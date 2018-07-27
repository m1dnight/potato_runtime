defmodule PotatoTest do
  use ExUnit.Case
  doctest Potato

  test "greets the world" do
    assert Potato.hello() == :world
  end
end
