defmodule ArchethicClient.TransactionData.Ledger.UCOLedger.Transfer do
  @moduledoc """
  Represents a single transfer of UCO (the native currency) within a transaction.

  Each UCO transfer specifies:
  - `to`: The recipient address for the UCO.
  - `amount`: The quantity of UCO to transfer (in its smallest unit, UCOents, where 1 UCO = 10^8 UCOents).

  This module provides functions for serializing UCO transfer data and converting it to a map.
  """

  alias ArchethicClient.Crypto

  defstruct [:to, :amount]

  @typedoc """
  A UCO transfer is composed of:
  - `to`: The recipient `Crypto.address/0` of the UCO.
  - `amount`: The non-negative integer amount of UCO to transfer (in the smallest unit, 10^-8).
  """
  @type t :: %__MODULE__{
          to: Crypto.address(),
          amount: non_neg_integer()
        }

  @doc """
  Serialize UCO transfer into binary format
  """
  def serialize(%__MODULE__{to: to, amount: amount}), do: <<to::binary, amount::64>>

  @doc """
  Converts a UCO `Transfer` struct to a map representation.

  The `to` address is Base16 encoded in the resulting map.
  """
  @spec to_map(uco_transfer :: t()) :: map()
  def to_map(%__MODULE__{to: to, amount: amount}), do: %{to: Base.encode16(to), amount: amount}
end
