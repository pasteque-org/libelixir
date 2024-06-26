defmodule ArchethicSDKTest do
  use ExUnit.Case
  doctest ArchethicSDK

  test "greets the world" do
    assert ArchethicSDK.hello() == :world
  end
end
