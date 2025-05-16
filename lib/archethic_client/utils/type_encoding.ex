defmodule ArchethicClient.Utils.TypedEncoding do
  @moduledoc """
  Provides functions for serializing and deserializing various Elixir data types
  into a compact, type-prefixed binary format.

  This encoding scheme is used to represent data such as transaction arguments or
  manifest contents in a space-efficient manner. Each serialized piece of data is
  prefixed with a type byte, followed by the data itself in a type-specific format.

  Supported types for serialization/deserialization include:
  - Integers (signed, variable-length encoding using `VarInt`)
  - Floats (converted to scaled integers before VarInt encoding)
  - Strings (binary, prefixed with VarInt encoded length)
  - Lists (prefixed with VarInt encoded count, elements are recursively serialized)
  - Maps (prefixed with VarInt encoded count of key-value pairs, keys and values are recursively serialized)
  - Booleans (single byte for type, followed by a bit for true/false)
  - Nil (single byte for type)
  """

  alias ArchethicClient.Utils
  alias ArchethicClient.Utils.VarInt

  @type_int 0
  @type_float 1
  @type_str 2
  @type_list 3
  @type_map 4
  @type_bool 5
  @type_nil 6

  @type arg() :: number() | boolean() | binary() | list() | map() | nil

  @doc """
  Serializes an Elixir data type into a type-prefixed binary format.
  """
  @spec serialize(arg()) :: binary()
  def serialize(int) when is_integer(int) do
    sign_bit = sign_to_bit(int)
    bin = int |> abs() |> VarInt.from_value()

    <<@type_int::8, sign_bit::8, bin::binary>>
  end

  def serialize(float) when is_float(float) do
    sign_bit = sign_to_bit(float)
    bin = float |> abs() |> Utils.to_bigint() |> VarInt.from_value()
    <<@type_float::8, sign_bit::8, bin::binary>>
  end

  def serialize(bin) when is_binary(bin) do
    size = byte_size(bin)
    size_bin = VarInt.from_value(size)
    <<@type_str::8, size_bin::binary, bin::binary>>
  end

  def serialize(list) when is_list(list) do
    size = length(list)
    size_bin = VarInt.from_value(size)

    Enum.reduce(list, <<@type_list::8, size_bin::binary>>, fn item, acc ->
      <<acc::binary, serialize(item)::binary>>
    end)
  end

  def serialize(map) when is_map(map) do
    size = map_size(map)
    size_bin = VarInt.from_value(size)

    Enum.reduce(map, <<@type_map::8, size_bin::binary>>, fn {k, v}, acc ->
      <<acc::binary, serialize(k)::binary, serialize(v)::binary>>
    end)
  end

  def serialize(bool) when is_boolean(bool) do
    bool_bit = if bool, do: 1, else: 0
    <<@type_bool::8, bool_bit::8>>
  end

  def serialize(nil), do: <<@type_nil::8>>

  defp sign_to_bit(num) when num >= 0, do: 1
  defp sign_to_bit(_num), do: 0
end
