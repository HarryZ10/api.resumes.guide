defmodule BackendwebserverTest do
  use ExUnit.Case
  doctest Backendwebserver

  test "greets the world" do
    assert Backendwebserver.hello() == :world
  end
end
