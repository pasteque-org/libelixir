defmodule ArchethicClient.TransactionData.Ownership do
  @moduledoc """
  Represents an ownership of a secret and the authorized public keys able to
  read the encrypted secret
  """

  alias ArchethicClient.Crypto
  alias ArchethicClient.Utils.VarInt

  defstruct authorized_keys: %{}, secret: ""

  @type t :: %__MODULE__{
          secret: binary(),
          authorized_keys: %{(public_key :: Crypto.key()) => encrypted_key :: binary()}
        }

  @doc """
  Create a new ownership by passing its secret with its authorized keys

  ## Examples

      iex> secret_key = :crypto.strong_rand_bytes(32)
      ...> secret = "important message"
      ...> {pub, _pv} = Crypto.generate_deterministic_keypair("seed")
      ...> %Ownership{authorized_keys: authorized_keys} = Ownership.new(secret, secret_key, [pub])
      ...> Map.keys(authorized_keys)
      [
        <<0, 1, 241, 101, 225, 229, 247, 194, 144, 229, 47, 46, 222, 243, 251, 171, 96, 203, 174,
          116, 191, 211, 39, 79, 142, 94, 225, 222, 51, 69, 201, 84, 161, 102>>
      ]
  """
  @spec new(secret :: binary(), authorized_keys :: list(Crypto.key()), secret_key :: binary()) :: t()
  def new(secret, authorized_keys, secret_key \\ :crypto.strong_rand_bytes(32)) do
    %__MODULE__{
      secret: secret,
      authorized_keys:
        Map.new(authorized_keys, fn public_key -> {public_key, Crypto.ec_encrypt(secret_key, public_key)} end)
    }
  end

  @doc """
  Serialize an ownership

  ## Examples

      iex> %Ownership{
      ...>   secret: <<205, 124, 251, 211, 28, 69, 249, 1, 58, 108, 16, 35, 23, 206, 198, 202>>,
      ...>   authorized_keys: %{
      ...>     <<0, 0, 229, 188, 159, 80, 100, 5, 54, 152, 137, 201, 204, 24, 22, 125, 76, 29, 83,
      ...>       14, 154, 60, 66, 69, 121, 97, 40, 215, 226, 204, 133, 54, 187,
      ...>       9>> =>
      ...>       <<139, 100, 20, 32, 187, 77, 56, 30, 116, 207, 34, 95, 157, 128, 208, 115, 113,
      ...>         177, 45, 9, 93, 107, 90, 254, 173, 71, 60, 181, 113, 247, 75, 151, 127, 41, 7,
      ...>         233, 227, 98, 209, 211, 97, 117, 68, 101, 59, 121, 214, 105, 225, 218, 91, 92,
      ...>         212, 162, 48, 18, 15, 181, 70, 103, 32, 141, 4, 64, 107, 93, 117, 188, 244, 7,
      ...>         224, 214, 225, 146, 44, 83, 111, 34, 239, 99>>
      ...>   }
      ...> }
      ...> |> Ownership.serialize()
      <<0, 0, 0, 16, 205, 124, 251, 211, 28, 69, 249, 1, 58, 108, 16, 35, 23, 206, 198, 202, 1, 1,
        0, 0, 229, 188, 159, 80, 100, 5, 54, 152, 137, 201, 204, 24, 22, 125, 76, 29, 83, 14, 154,
        60, 66, 69, 121, 97, 40, 215, 226, 204, 133, 54, 187, 9, 139, 100, 20, 32, 187, 77, 56, 30,
        116, 207, 34, 95, 157, 128, 208, 115, 113, 177, 45, 9, 93, 107, 90, 254, 173, 71, 60, 181,
        113, 247, 75, 151, 127, 41, 7, 233, 227, 98, 209, 211, 97, 117, 68, 101, 59, 121, 214, 105,
        225, 218, 91, 92, 212, 162, 48, 18, 15, 181, 70, 103, 32, 141, 4, 64, 107, 93, 117, 188,
        244, 7, 224, 214, 225, 146, 44, 83, 111, 34, 239, 99>>
  """
  @spec serialize(ownership :: t()) :: binary()
  def serialize(%__MODULE__{secret: secret, authorized_keys: authorized_keys}) do
    authorized_keys_bin =
      authorized_keys
      |> Enum.map(fn {public_key, encrypted_key} -> <<public_key::binary, encrypted_key::binary>> end)
      |> :erlang.list_to_binary()

    serialized_length = VarInt.from_value(map_size(authorized_keys))

    <<byte_size(secret)::32, secret::binary, serialized_length::binary, authorized_keys_bin::binary>>
  end

  @spec to_map(ownership :: t()) :: map()
  def to_map(%__MODULE__{secret: secret, authorized_keys: authorized_keys}) do
    %{
      secret: Base.encode16(secret),
      authorizedKeys: Map.new(authorized_keys, fn {pub, key} -> {Base.encode16(pub), Base.encode16(key)} end)
    }
  end
end
