defmodule ArchethicClient.TransactionData.Recipient do
  @moduledoc """
  Represents a call to a Smart Contract

  Action & Args are nil for a :transaction trigger and are filled for a {:transaction, action, args} trigger
  """
  alias ArchethicClient.Crypto
  alias ArchethicClient.Utils.TypedEncoding

  defstruct [:address, :action, :args]

  @type t :: %__MODULE__{
          address: Crypto.address(),
          action: String.t() | nil,
          args: list(any()) | nil
        }

  @doc """
  Serialize a recipient
  """
  @spec serialize(recipient :: t()) :: binary()
  def serialize(%__MODULE__{address: address, action: action, args: args}) do
    serialized_args = args |> Enum.map(&TypedEncoding.serialize/1) |> :erlang.list_to_binary()

    <<1::8, address::binary, byte_size(action)::8, action::binary, length(args)::8, serialized_args::binary>>
  end

  @doc false
  @spec to_map(recipient :: t()) :: map()
  def to_map(%__MODULE__{address: address, action: action, args: args}),
    do: %{address: Base.encode16(address), action: action, args: args}
end
