defmodule ArchethicClient.TransactionData.Ledger do
  @moduledoc """
  Represents ledger movements within a transaction, encompassing both UCO (native currency)
  and token transfers.

  This struct aggregates `UCOLedger` and `TokenLedger` data, providing a unified view
  of all asset movements in a transaction. It includes functions for serialization
  and map conversion.
  """

  alias __MODULE__.TokenLedger
  alias __MODULE__.UCOLedger

  defstruct uco: %UCOLedger{}, token: %TokenLedger{}

  @typedoc """
  Ledger movements are composed from:
  - UCO: movements of UCO
  """
  @type t :: %__MODULE__{
          uco: UCOLedger.t(),
          token: TokenLedger.t()
        }

  @doc """
  Serialize the ledger into binary format
  """
  @spec serialize(transaction_ledger :: t()) :: binary()
  def serialize(%__MODULE__{uco: uco_ledger, token: token_ledger}),
    do: <<UCOLedger.serialize(uco_ledger)::binary, TokenLedger.serialize(token_ledger)::binary>>

  @doc """
  Converts a `Ledger` struct into a map representation.
  """
  @spec to_map(ledger :: t()) :: map()
  def to_map(%__MODULE__{uco: uco, token: token}) do
    %{
      uco: UCOLedger.to_map(uco),
      token: TokenLedger.to_map(token)
    }
  end
end
