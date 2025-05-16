defmodule ArchethicClient.Utils.VarInt do
  @moduledoc """
    Provides functions for encoding integers into a variable-length binary format
    and decoding them back.
  """

  @doc """
  Encodes an integer into a VarInt binary format.

  The function first determines the minimum number of bytes required to store the integer value.
  This count (1-255) is then prepended as a single byte to the actual integer value (stored in N bytes).

  ## Examples
      iex> ArchethicClient.Utils.VarInt.from_value(200)
      <<1, 200>>
      iex> ArchethicClient.Utils.VarInt.from_value(300)
      <<2, 1, 44>> # 300 = 256 * 1 + 44
  """
  @spec from_value(integer()) :: binary()
  def from_value(value) do
    bytes = min_bytes_to_store(value)
    <<bytes::8, value::bytes*8>>
  end

  @spec min_bytes_to_store(integer()) :: integer()
  defp min_bytes_to_store(value) do
    Enum.find(1..255, fn x -> value < Integer.pow(2, 8 * x) end)
  end
end
