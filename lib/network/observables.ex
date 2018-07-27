defmodule Potato.Network.Observables do
  @moduledoc """
  A GenServer template for a "singleton" process.
  """
  use GenServer
  import GenServer
  require Logger

  alias Potato.Network.Meta

  def start_link(opts \\ []) do
    start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    Registry.register(Potato.PubSub, :node_descriptors, [])

    # Setup the initial observables.
    network = Observables.Subject.create()
    bluetooth = Observables.Subject.create()

    state = %{:network => network, :bluetooth => bluetooth}
    {:ok, state}
  end

  #
  # ------------------------ API 
  #

  def network(), do: call(__MODULE__, :network)

  def bluetooth(), do: call(__MODULE__, :bluetooth)

  #
  # ------------------------ Callbacks 
  #

  def handle_call({:added, remote, nd}, _from, state) do
    Observables.Subject.next(state.network, {:join, nd})
    {:reply, :ok, state}
  end

  def handle_call({:removed, remote, nd}, _from, state) do
    Observables.Subject.next(state.network, {:part, nd})
    {:reply, :ok, state}
  end

  def handle_call(:network, _from, state) do
    # Prepend with current nodes.
    current = 
    Meta.current_network()
    |> Enum.map(fn n -> {:join, n} end)

    observable = state.network |> Observables.Obs.starts_with(current) 

    {:reply, observable, state}
  end

  def handle_call(:bluetooth, _from, state) do
    {:reply, state.bluetooth, state}
  end
end
