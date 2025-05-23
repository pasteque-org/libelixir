defmodule ArchethicClient.Utils do
  @moduledoc """
  Provides a collection of utility functions used throughout the ArchethicClient library.

  This module includes helpers for binary manipulation and number conversions, particularly
  for handling big integers and decimal values common in blockchain interactions.
  """

  @doc """
  Wrap any bitstring which is not byte even by padding the remaining bits to make an even binary

  ## Examples

      iex> ArchethicClient.Utils.wrap_binary(<<1::1>>)
      <<1::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>

      iex> ArchethicClient.Utils.wrap_binary(<<33, 50, 10>>)
      <<33, 50, 10>>

      iex> ArchethicClient.Utils.wrap_binary([<<1::1, 1::1, 1::1>>, "hello"])
      <<1::1, 1::1, 1::1, 0::1, 0::1, 0::1, 0::1, 0::1, "hello"::binary>>

      iex> ArchethicClient.Utils.wrap_binary([[<<1::1, 1::1, 1::1>>, "abc"], "hello"])
      <<1::1, 1::1, 1::1, 0::1, 0::1, 0::1, 0::1, 0::1, "abc"::binary, "hello"::binary>>
  """
  @spec wrap_binary(iodata() | bitstring() | list(bitstring())) :: binary()
  def wrap_binary(bits) when is_binary(bits), do: bits

  def wrap_binary(bits) when is_bitstring(bits) do
    size = bit_size(bits)

    if rem(size, 8) == 0 do
      bits
    else
      # Find out the next greater multiple of 8
      round_up = Bitwise.band(size + 7, -8)
      pad_bitstring(bits, round_up - size)
    end
  end

  def wrap_binary(bits) when is_list(bits), do: do_wrap_binary(bits, [])

  defp do_wrap_binary([data | rest], acc) when is_list(data) do
    iolist = data |> Enum.reduce([], &[wrap_binary(&1) | &2]) |> Enum.reverse()
    do_wrap_binary(rest, [iolist | acc])
  end

  defp do_wrap_binary([data | rest], acc) when is_bitstring(data), do: do_wrap_binary(rest, [wrap_binary(data) | acc])
  defp do_wrap_binary([], acc), do: acc |> Enum.reverse() |> List.flatten() |> Enum.join()

  # Pads a bitstring with zero bits to make its length a multiple of 8.
  defp pad_bitstring(original_bits, additional_bits), do: <<original_bits::bitstring, 0::size(additional_bits)>>

  @doc """
  Convert a number to a bigint
  """
  @spec to_bigint(value :: integer() | float() | String.t() | Decimal.t(), decimals :: non_neg_integer()) :: integer()
  def to_bigint(value, decimals \\ 8)
  def to_bigint(value, decimals) when is_integer(value), do: value * get_factor(decimals)
  def to_bigint(%Decimal{} = value, decimals), do: do_to_big_int(value, decimals)
  def to_bigint(value, decimals) when is_float(value), do: value |> Decimal.from_float() |> do_to_big_int(decimals)
  def to_bigint(value, decimals) when is_binary(value), do: value |> Decimal.new() |> do_to_big_int(decimals)

  defp do_to_big_int(dec, decimals) do
    dec
    |> Decimal.mult(get_factor(decimals))
    |> Decimal.round(0, :floor)
    |> Decimal.to_integer()
  end

  @doc """
  Convert a bigint to a string | float | Decimal.t()
  """
  @spec from_bigint(bigint :: integer(), decimals :: non_neg_integer()) :: String.t()
  def from_bigint(bigint, decimals \\ 8),
    do: bigint |> Decimal.new() |> Decimal.div(get_factor(decimals)) |> Decimal.to_string(:normal)

  defp get_factor(decimals), do: 10 |> :math.pow(decimals) |> trunc()
end
