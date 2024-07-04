defmodule ArchethicClientTest do
  use ExUnit.Case

  doctest ArchethicClient

  test "greets the world" do
    assert ArchethicClient.hello() == :world
  end
end
