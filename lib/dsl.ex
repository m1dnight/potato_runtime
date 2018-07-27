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
  Deploy takes a piece of code and deploys it on the remote node.
  """
  defmacro deploy(alias, do: body) do
    quote do
      Potato.Network.Sender.deploy_remote(
        fn ->
          unquote(body)
        end,
        var!(unquote(alias)).host
      )
    end
  end

  @doc """
  Program tunkifies a given piece of code.
  """
  defmacro program(do: body) do
    quote do
      fn ->
        unquote(body)
      end
    end
  end

  @doc """
  myself() evaluates to the local node descriptor.
  """
  def myself() do
    {:ok, ddf} = Potato.Network.DDF.local_ddf()
    IO.inspect(ddf)
    ddf.observable
  end
end
