defmodule ArchethicClient.Crypto.Ed25519 do
  @moduledoc """
  Module for Ed25519 key pair generation and signing/verification.
  """

  import Bitwise

  @p 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED

  @doc """
  Generate an Ed25519 key pair
  """
  @spec generate_keypair(binary()) :: {binary(), binary()}
  def generate_keypair(seed) when is_binary(seed) and byte_size(seed) < 32 do
    seed = :crypto.hash(:sha256, seed)
    do_generate_keypair(seed)
  end

  def generate_keypair(seed) when is_binary(seed) and byte_size(seed) > 32,
    do: do_generate_keypair(:binary.part(seed, 0, 32))

  def generate_keypair(seed) when is_binary(seed), do: do_generate_keypair(seed)

  defp do_generate_keypair(seed), do: :crypto.generate_key(:eddsa, :ed25519, seed)

  @doc """
  Sign a message with the given Ed25519 private key
  """
  @spec sign(binary(), iodata()) :: binary()
  def sign(<<private_key::binary-32>> = _key, data) when is_binary(data) or is_list(data),
    do: :crypto.sign(:eddsa, :sha512, data, [private_key, :ed25519])

  @doc """
  Verify if a given Ed25519 public key matches the signature among with its data
  """
  @spec verify?(binary(), binary(), binary()) :: boolean()
  def verify?(<<public_key::binary-32>>, data, sig) when (is_binary(data) or is_list(data)) and is_binary(sig),
    do: :crypto.verify(:eddsa, :sha512, data, sig, [public_key, :ed25519])

  @doc """
  Converts an Ed25519 private key to an X25519 private key.
  """
  @spec convert_to_x25519_private_key(ed25519_private_key :: binary()) :: binary()
  def convert_to_x25519_private_key(ed25519_private_key) when byte_size(ed25519_private_key) == 32 do
    :sha512
    |> :crypto.hash(ed25519_private_key)
    |> :binary.part(0, 32)
    |> clamp_curve25519_key()
  end

  defp clamp_curve25519_key(<<first::8, middle::bytes-size(30), last::8>>) do
    clamped = <<first &&& 0b11111000>> <> middle <> <<(last &&& 0b00111111) ||| 0b01000000>>
    :binary.copy(clamped)
  end

  @doc """
  Converts an Ed25519 public key to an X25519 public key.
  """
  @spec convert_to_x25519_public_key(ed25519_public_key :: binary()) :: binary()
  def convert_to_x25519_public_key(ed25519_public_key) when byte_size(ed25519_public_key) == 32 do
    # Extract y-coordinate (clearing sign bit)
    <<y_bytes::binary-size(31), last_byte>> = ed25519_public_key
    y = :binary.decode_unsigned(y_bytes <> <<last_byte &&& 0x7F>>, :little)

    # Compute u = (1 + y) / (1 - y) mod p (using non-negative mod)
    numerator = Integer.mod(1 + y, @p)
    denominator = Integer.mod(1 - y, @p)
    inv_denominator = mod_pow(denominator, @p - 2, @p)
    u = Integer.mod(numerator * inv_denominator, @p)

    # Encode as X25519 key
    <<u::little-unsigned-integer-size(256)>>
  end

  defp mod_pow(base, exp, mod) when base >= 0 and mod > 0 do
    base_bin = :binary.encode_unsigned(base)
    exp_bin = :binary.encode_unsigned(exp)
    mod_bin = :binary.encode_unsigned(mod)

    base_bin |> :crypto.mod_pow(exp_bin, mod_bin) |> :binary.decode_unsigned()
  end
end
