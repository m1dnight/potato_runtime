defmodule Potato.Network.Meta do
  @moduledoc """
  All Potato nodes on the network are connected at the lowest level. 

  This process gathers meta data about the nodes, more specifically, 
  the node descriptor for each node in the network.
  """
  use GenServer
  require Logger
  import GenServer
  alias Potato.Network.Meta

  defstruct others: %{}, self: %{}

  def start_link() do
    start_link(__MODULE__, [], [{:name, __MODULE__}])
  end

  def init([]) do
    Registry.register(Potato.PubSub, :discover, [])

    # We need to get the deployment subject from the Observables first. 
    # We can not go online without it.
    # We safely assume it has been started before us.
    deployment_subject = Potato.Network.Observables.deployment()

    {:ok, %Meta{self: %{:deploy => deployment_subject}}}
  end

  #
  # ------------------------ API
  #

  @doc """
  Sets our local node descriptor. Should be setup by the application using the runtime.
  """
  def set_local_nd(map), do: call(__MODULE__, {:set_local_nd, map})

  @doc """
  Returns a list of the currently connected network descriptors.
  """
  def current_network(), do: call(__MODULE__, :current_network)

  @doc """
  Prints out some data of the local network. Useful for debugging.
  """
  def dump(), do: call(__MODULE__, :dump)

  #
  # ------------------------ Callbacks
  #

  def handle_call({:found, remote}, _from, state) do
    new_state = handle_join(remote, state)
    {:reply, :ok, new_state}
  end

  def handle_call({:lost, remote}, _from, state) do
    new_state = handle_part(remote, state)
    {:reply, :ok, new_state}
  end

  def handle_call({:set_local_nd, map}, _from, state) do
    # Update our own ND in the state.
    new_self = Map.merge(map, state.self)
    new_state = %{state | self: new_self}
    # Notify the network that we have updated our ND.
    broadcast_local_node_descriptor(new_state)
    {:reply, :ok, new_state}
  end

  def handle_call(:current_network, _from, state) do
    {:reply, Map.values(state.others), state}
  end

  def handle_call(:dump, _from, state) do
    dump_state(state)
    {:reply, :ok, state}
  end

  def handle_cast({:set_remote_nd, remote, map}, state) do
    # If the new ND is not nil, we store it.
    if valid_nd?(map) do
      Logger.debug("Remote ND for #{inspect(remote)}")
      new_state = %{state | others: Map.put(state.others, remote, map)}
      Potato.PubSub.call_all(:node_descriptors, {:added, remote, map})
      {:noreply, new_state}
    else
      Logger.warn "Remote ND was not valid: #{inspect map}"
      {:noreply, state}
    end
  end

  #
  # ------------------------ Helpers
  #

  defp send_local_nd_to_remote(state, remote) do
    cast({__MODULE__, remote}, {:set_remote_nd, Node.self(), state.self})
  end

  defp broadcast_local_node_descriptor(state) do
    abcast(Node.list(), __MODULE__, {:set_remote_nd, Node.self(), state.self})
  end

  defp handle_join(remote, state) do
    # Send our node descriptor to the newly joined node.
    if valid_nd?(state.self) do
      send_local_nd_to_remote(state, remote)
    else
      Logger.warn "We don't have a valid ND ourselves, so we are not broadcasting it yet!"
    end
    state
  end

  defp handle_part(remote, state) do
    old_nd = Map.get(state.others, remote)
    new_state = %{state | others: Map.delete(state.others, remote)}
    Potato.PubSub.call_all(:node_descriptors, {:removed, remote, old_nd})
    new_state
  end

  defp valid_nd?(nd) do
    Map.has_key?(nd, :hardware)
    and Map.has_key?(nd, :type)
    and Map.has_key?(nd, :name)
    and Map.has_key?(nd, :uuid)

  end

  defp dump_state(state) do
    net =
      state.others
      |> Map.to_list()
      |> Enum.map(fn {r, nd} ->
        "#{inspect(r)}\n#{inspect(nd)}"
      end)
      |> Enum.reduce("", fn x, acc -> x <> "\n" <> acc end)

    Logger.debug("""

    Self
    ======================================
    PID: #{inspect(Node.self())}
    ND : #{inspect(state.self)}

    Nodes
    ======================================
    #{inspect(Node.list())}


    Node descriptors
    ======================================
    #{net}
    """)
  end
end
