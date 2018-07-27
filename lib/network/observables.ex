defmodule Potato.Network.Observables do
  @moduledoc """
  A GenServer template for a "singleton" process.
  """
  use GenServer
  import GenServer
  require Logger


  def start_link(opts \\ []) do
    start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    state = %{}
    {:ok, state}
  end

  #
  # ------------------------ API 
  #

  #
  # ------------------------ Callbacks 
  #

  def handle_call(m, from, state) do
    {:reply, :response, state}
  end

  def handle_cast(m, state) do
    {:noreply, state}
  end

  def handle_info(m, state) do
    {:noreply, state}
  end

  #
  # ------------------------ Helpers 
  #

  defp private(x) do
    x
  end
end
