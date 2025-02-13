defmodule ArchethicClient.Utils do
  @moduledoc """
  Provide utility functions
  """

  @doc """
  Wrap any bitstring which is not byte even by padding the remaining bits to make an even binary

  ## Examples

      iex> Utils.wrap_binary(<<1::1>>)
      <<1::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>

      iex> Utils.wrap_binary(<<33, 50, 10>>)
      <<33, 50, 10>>

      iex> Utils.wrap_binary([<<1::1, 1::1, 1::1>>, "hello"])
      <<1::1, 1::1, 1::1, 0::1, 0::1, 0::1, 0::1, 0::1, "hello"::binary>>

      iex> Utils.wrap_binary([[<<1::1, 1::1, 1::1>>, "abc"], "hello"])
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

  def wrap_binary(data, acc \\ [])

  def wrap_binary([data | rest], acc) when is_list(data) do
    iolist = data |> Enum.reduce([], &[wrap_binary(&1) | &2]) |> Enum.reverse()
    wrap_binary(rest, [iolist | acc])
  end

  def wrap_binary([data | rest], acc) when is_bitstring(data), do: wrap_binary(rest, [wrap_binary(data) | acc])
  def wrap_binary([], acc), do: acc |> Enum.reverse() |> List.flatten() |> Enum.join()

  defp pad_bitstring(original_bits, additional_bits), do: <<original_bits::bitstring, 0::size(additional_bits)>>

  @doc """
  Convert a number to a bigint
  """
  @spec to_bigint(integer() | float() | String.t() | Decimal.t(), decimals :: non_neg_integer()) :: integer()
  def to_bigint(valuen, decimals \\ 8)
  def to_bigint(value, decimals) when is_integer(value), do: value * get_mult(decimals)
  def to_bigint(%Decimal{} = value, decimals), do: do_to_big_int(value, decimals)
  def to_bigint(value, decimals) when is_float(value), do: value |> Decimal.from_float() |> do_to_big_int(decimals)
  def to_bigint(value, decimals) when is_binary(value), do: value |> Decimal.new() |> do_to_big_int(decimals)

  defp do_to_big_int(dec, decimals) do
    dec
    |> Decimal.mult(get_mult(decimals))
    |> Decimal.round(0, :floor)
    |> Decimal.to_integer()
  end

  defp get_mult(decimals), do: 10 |> :math.pow(decimals) |> trunc()
end
