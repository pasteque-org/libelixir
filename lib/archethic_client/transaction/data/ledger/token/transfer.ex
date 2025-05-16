defmodule ArchethicClient.TransactionData.Ledger.TokenLedger.Transfer do
  @moduledoc """
  Represents a single transfer of a fungible or non-fungible token within a transaction.

  Each token transfer specifies:
  - `token_address`: The address of the token contract.
  - `to`: The recipient address for the token.
  - `amount`: The quantity of the token to transfer (in its smallest unit, e.g., 10^-8 for tokens with 8 decimal places).
  - `token_id`: For non-fungible tokens (NFTs) or token collections, this identifies the specific token instance. Defaults to 0.
  - `conditions`: (Currently not utilized in serialization or map conversion) A list of addresses to which the token can be further transferred or used.

  This module provides functions for serializing token transfer data and converting it to a map.
  """
  alias ArchethicClient.Utils.VarInt

  defstruct [:to, :amount, :token_address, conditions: [], token_id: 0]

  @typedoc """
  Transfer is composed from:
  - token_address: Token address
  - to: receiver address of the asset
  - amount: specify the number of Token to transfer to the recipients (in the smallest unit 10^-8)
  - conditions: specify to which address the Token can be used
  - token_id: To uniquely identify a token from a set a of token(token collection)
  """
  @type t :: %__MODULE__{
          token_address: binary(),
          to: binary(),
          amount: non_neg_integer(),
          conditions: list(binary()),
          token_id: non_neg_integer()
        }

  @doc """
  Serialize Token transfer into binary format
  """
  @spec serialize(token_transfer :: t()) :: binary()
  def serialize(%__MODULE__{token_address: token, to: to, amount: amount, token_id: token_id}),
    do: <<token::binary, to::binary, amount::64, VarInt.from_value(token_id)::binary>>

  @doc """
  Converts a token `Transfer` struct to a map representation.
  """
  @spec to_map(token_transfer :: t()) :: map()
  def to_map(%__MODULE__{token_address: token_address, to: to, amount: amount, token_id: token_id}) do
    %{
      tokenAddress: Base.encode16(token_address),
      to: Base.encode16(to),
      amount: amount,
      tokenId: token_id
    }
  end
end
