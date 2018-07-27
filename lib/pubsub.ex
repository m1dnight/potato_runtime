defmodule Potato.PubSub do
  def register(pid, type, register \\ __MODULE__) do
    Registry.register(register, type, [])
  end

  def cast_all(type, message, register \\ __MODULE__) do
    Registry.dispatch(register, type, fn entries ->
      for {pid, _} <- entries do
        GenServer.cast(pid, message)
      end
    end)
  end

  def call_all(type, message, register \\ __MODULE__) do
    Registry.dispatch(register, type, fn entries ->
      for {pid, _} <- entries do
        GenServer.call(pid, message)
      end
    end)
  end
end
