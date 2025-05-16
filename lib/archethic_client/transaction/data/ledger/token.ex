defmodule ArchethicClient.TransactionData.Ledger.TokenLedger do
  @moduledoc """
  Represents ledger movements specifically for fungible or non-fungible tokens.

  This struct holds a list of `ArchethicClient.TransactionData.Ledger.TokenLedger.Transfer`
  records, detailing each token movement within a transaction.
  It provides functions for serialization and map conversion of these token ledger entries.
  """
  alias __MODULE__.Transfer
  alias ArchethicClient.Utils.VarInt

  defstruct transfers: []

  @typedoc """
  Token ledger movement is composed from:
  - `transfers`: A list of `ArchethicClient.TransactionData.Ledger.TokenLedger.Transfer.t()` records.
  """
  @type t :: %__MODULE__{
          transfers: list(Transfer.t())
        }

  @doc """
  Serialize a Token ledger into binary format
  """
  @spec serialize(token_ledger :: t()) :: binary()
  def serialize(%__MODULE__{transfers: transfers}) do
    transfers_bin = transfers |> Enum.map(&Transfer.serialize/1) |> :erlang.list_to_binary()

    encoded_transfer = transfers |> length() |> VarInt.from_value()
    <<encoded_transfer::binary, transfers_bin::binary>>
  end

  @spec to_map(token_ledger :: t()) :: map()
  def to_map(%__MODULE__{transfers: transfers}), do: %{transfers: Enum.map(transfers, &Transfer.to_map/1)}
end
