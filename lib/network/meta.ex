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

  defstruct others: %{}, self: nil

  def start_link() do
    start_link(__MODULE__, [], [{:name, __MODULE__}])
  end

  def init([]) do
    {:ok, %Meta{}}
  end

  #
  # ------------------------ API
  #

  @doc """
  Notify the lobby of a node that joined the network.
  """
  def join(remote), do: call(__MODULE__, {:join, remote})

  @doc """
  Notify the lobby of a node that parted the network.
  """
  def part(remote), do: call(__MODULE__, {:part, remote})

  @doc """
  Sets our local node descriptor. Should be setup by the application using the runtime.
  """
  def set_local_nd(map), do: call(__MODULE__, {:set_local_nd, map})

  @doc """
  Prints out some data of the local network. Useful for debugging.
  """
  def dump(), do: call(__MODULE__, :dump)

  #
  # ------------------------ Callbacks
  #

  def handle_call({:join, remote}, _from, state) do
    new_state = handle_join(remote, state)
    {:reply, :ok, new_state}
  end

  def handle_call({:part, remote}, _from, state) do
    new_state = handle_part(remote, state)
    {:reply, :ok, new_state}
  end

  def handle_call({:set_local_nd, map}, _from, state) do
    # Update our own ND in the state.
    new_state = %{state | self: map}
    # Notify the network that we have updated our ND.
    broadcast_local_node_descriptor(new_state)
    {:reply, :ok, new_state}
  end

  def handle_call(:dump, _from, state) do
    dump_state(state)
    {:reply, :ok, state}
  end

  def handle_cast({:set_remote_nd, remote, map}, state) do
    # If the new ND is not nil, we store it.
    if nil != map do
      Logger.debug("Remote ND for #{inspect(remote)}")
      new_state = %{state | others: Map.put(state.others, remote, map)}
      {:noreply, new_state}
    else
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
    send_local_nd_to_remote(state, remote)
    state
  end

  defp handle_part(remote, state) do
    new_state = %{state | others: Map.delete(state.others, remote)}
    new_state
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
