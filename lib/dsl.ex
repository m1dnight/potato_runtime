defmodule Potato.DSL do
  @moduledoc """

  The DSL module implements the language constructs needed to effectively write
  Potato programs.
  """

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)
      require unquote(__MODULE__)
    end
  end

  #
  # ------------------------ Macros
  #

  @doc """
  myself() evaluates to the local node descriptor.
  """
  def myself() do
    myself = Potato.Network.Observables.myself()
    myself
  end
end
