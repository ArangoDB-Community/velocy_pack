defmodule VelocyPackTest do
  use ExUnit.Case
  doctest VelocyPack

  test "greets the world" do
    assert VelocyPack.hello() == :world
  end
end
