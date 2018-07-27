defmodule Potato.Application do
  require Logger

  @moduledoc """
  Starts up all the modules required to operate Potato.
  """

  def start(_type, _args) do
    Logger.debug("Starting the Potato runtime!")
    import Supervisor.Spec, warn: false

    children = [
      worker(Registry, [
        [keys: :duplicate, name: Potato.PubSub, partitions: System.schedulers_online()]
      ]),
      worker(Potato.Network.Observables, []),
      worker(Potato.Network.Evaluator, []),
      worker(Potato.Network.Meta, []),
      worker(Potato.Network.Broadcast, [])
    ]

    opts = [strategy: :one_for_one, name: Potato.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
