defmodule Potato.Network.Broadcast do
  @moduledoc """
  This module is responsible for scanning the network. We assume that each
  participant on the network is running this module, too.

  As soon as the process is started it will broadcast itself on the network via
  UDP. The goal here is to do this over multiple protocols.

  By exploiting the Erlang `:net_kernel.monitor_nodes` functionality we are
  notified as soon as a new node enter the network.

  In case of a new node we signal the actor spawned by `Network.Lobby`.
  In case of a node disconnect we signal `Network.Lobby` as well.
  """
  use GenServer
  require Logger
  alias Potato.Network.Meta

  @port 6666
  @multicast {239, 0, 0, 250}

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    # Detect timeouts ASAP.
    :net_kernel.set_net_ticktime(5, 0)
    :net_kernel.monitor_nodes(true)

    {:ok, s} =
      :gen_udp.open(@port, [
        :binary,
        {:reuseaddr, true},
        {:ip, @multicast},
        {:multicast_ttl, 4},
        {:multicast_loop, true},
        {:broadcast, true},
        {:add_membership, {@multicast, {0, 0, 0, 0}}},
        {:active, true}
      ])

    announce()
    {:ok, s}
  end

  #
  # ------------------------ API 
  #

  @doc """
  This function is called when a packet arrives on the UDP socket.
  This signifies an announce from a new node.
  The node is connected to.
  """
  def handle_info({:udp, _clientSocket, _clientIp, _clientPort, msg}, socket) do
    handle_discovery(msg)
    {:noreply, socket}
  end

  @doc """
  This message is receives when a node returns. (Result of monitoring nodes).
  """
  def handle_info({:nodeup, remote}, socket) do
    handle_connect(remote)
    {:noreply, socket}
  end

  @doc """
  This message is received when a node disappears from the network.
  """
  def handle_info({:nodedown, remote}, socket) do
    handle_disconnect(remote)
    {:noreply, socket}
  end

  #
  # ------------------------ Helpers
  #

  defp announce() do
    Logger.debug("Announcing our presence on the network")
    {:ok, sender} = :gen_udp.open(0, mode: :binary)
    :ok = :gen_udp.send(sender, @multicast, @port, "#{Node.self()}")
  end

  defp handle_disconnect(remote) do
    Logger.debug("LOST: #{inspect(remote)}")
    Potato.PubSub.call_all(:discover, {:lost, remote})
  end

  defp handle_connect(remote) do
    Logger.debug("DISCOVER: #{inspect(remote)}")
    Potato.PubSub.call_all(:discover, {:found, remote})
  end

  defp handle_discovery(msg) do
    hostname = String.to_atom(msg)
    Node.connect(hostname)
  end
end
