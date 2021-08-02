defmodule TflInterpTest do
  use ExUnit.Case
  doctest TflInterp

  test "greets the world" do
    assert TflInterp.hello() == :world
  end
end
