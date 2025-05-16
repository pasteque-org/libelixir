defmodule ArchethicClient.TransactionData.Recipient do
  @moduledoc """
  Represents a recipient of a transaction, typically for smart contract interactions.

  A recipient record specifies:
  - `address`: The address of the target smart contract.
  - `action`: The name of the function (action) to be called on the smart contract.
  - `args`: A map of arguments to be passed to the smart contract function.
  """
  alias ArchethicClient.Crypto
  alias ArchethicClient.Utils.TypedEncoding

  defstruct [:address, :action, :args]

  @type t :: %__MODULE__{
          address: Crypto.address(),
          action: String.t(),
          args: map() | nil
        }

  @doc """
  Serialize a recipient
  """
  @spec serialize(recipient :: t()) :: binary()
  def serialize(%__MODULE__{address: address, action: action, args: args}) do
    <<1::8, address::binary, byte_size(action)::8, action::binary, TypedEncoding.serialize(args)::binary>>
  end

  @doc """
  Converts a `Recipient` struct into a map representation.

  The `address` field is Base16 encoded in the resulting map.
  The `action` and `args` fields are included as is.
  """
  @spec to_map(recipient :: t()) :: map()
  def to_map(%__MODULE__{address: address, action: action, args: args}),
    do: %{address: Base.encode16(address), action: action, args: args}
end
