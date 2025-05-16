defmodule ArchethicClient.TransactionData.Ownership do
  @moduledoc """
  Represents an ownership record for a secret within a transaction.

  An ownership consists of:
  - `secret`: The actual secret data (binary).
  - `authorized_keys`: A map where keys are the public keys (`Crypto.key/0`) of entities
    authorized to decrypt the `secret_key`, and values are the `secret_key` itself,
    encrypted with the corresponding public key.
  """

  alias ArchethicClient.Crypto
  alias ArchethicClient.Utils.VarInt

  defstruct authorized_keys: %{}, secret: ""

  @type t :: %__MODULE__{
          secret: binary(),
          authorized_keys: %{(public_key :: Crypto.key()) => encrypted_key :: binary()}
        }

  @doc """
  Create a new ownership by passing its secret, a list of authorized public keys,
  and a secret key.

  The `secret_key` is encrypted for each public key in `authorized_keys` using ECIES.
  The provided `secret` is stored directly. If this `secret` needs to be encrypted
  by the `secret_key`, that must be done by the caller before invoking this function.
  """
  @spec new(secret :: binary(), authorized_keys :: list(Crypto.key()), secret_key :: binary()) :: t()
  def new(secret, authorized_keys, secret_key \\ :crypto.strong_rand_bytes(32)) do
    %__MODULE__{
      secret: Crypto.aes_encrypt(secret, secret_key),
      authorized_keys:
        Map.new(authorized_keys, fn public_key -> {public_key, Crypto.ec_encrypt(secret_key, public_key)} end)
    }
  end

  @doc """
  Serialize an ownership
  """
  @spec serialize(ownership :: t()) :: binary()
  def serialize(%__MODULE__{secret: secret, authorized_keys: authorized_keys}) do
    authorized_keys_bin =
      authorized_keys
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {public_key, encrypted_key} -> <<public_key::binary, encrypted_key::binary>> end)
      |> :erlang.list_to_binary()

    serialized_length = VarInt.from_value(map_size(authorized_keys))

    <<byte_size(secret)::32, secret::binary, serialized_length::binary, authorized_keys_bin::binary>>
  end

  @spec to_map(ownership :: t()) :: map()
  def to_map(%__MODULE__{secret: secret, authorized_keys: authorized_keys}) do
    mapped_authorized_keys =
      authorized_keys
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {pub, key} -> %{publicKey: Base.encode16(pub), encryptedSecretKey: Base.encode16(key)} end)

    %{
      secret: Base.encode16(secret),
      authorizedKeys: mapped_authorized_keys
    }
  end
end
