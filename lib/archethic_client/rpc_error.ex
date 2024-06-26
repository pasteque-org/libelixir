defmodule ArchethicClient.RPCError do
  @moduledoc """
  Represent an error returned by the Archethic network using RPC request
  """

  defexception [:message, :code, :data]
end
