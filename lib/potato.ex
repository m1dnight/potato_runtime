defmodule Potato.Application do
  require Logger

  @moduledoc """
  Starts up all the modules required to operate Potato.
  """

  def start(_type, _args) do
    Logger.debug("Starting the Potato runtime!")
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: Network.Worker.start_link(arg1, arg2, arg3)
      worker(Potato.Network.Meta, []),
      worker(Potato.Network.Broadcast, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Potato.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
