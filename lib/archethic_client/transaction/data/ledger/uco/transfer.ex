defmodule ArchethicClient.TransactionData.Ledger.UCOLedger.Transfer do
  @moduledoc """
  Represents a UCO transfer
  """

  alias ArchethicClient.Crypto

  defstruct [:to, :amount]

  @typedoc """
  Transfer is composed from:
  - to: receiver address of the UCO
  - amount: specify the number of UCO to transfer to the recipients (in the smallest unit 10^-8)
  - conditions: specify to which address the UCO can be used
  """
  @type t :: %__MODULE__{
          to: Crypto.address(),
          amount: non_neg_integer()
        }

  @doc """
  Serialize UCO transfer into binary format

  ## Examples

      iex> %Transfer{
      ...>   to:
      ...>     <<0, 104, 134, 142, 120, 40, 59, 99, 108, 63, 166, 143, 250, 93, 186, 216, 117, 85,
      ...>       106, 43, 26, 120, 35, 44, 137, 243, 184, 160, 251, 223, 0, 93, 14>>,
      ...>   amount: 1_050_000_000
      ...> }
      ...> |> Transfer.serialize()
      <<0, 104, 134, 142, 120, 40, 59, 99, 108, 63, 166, 143, 250, 93, 186, 216, 117, 85, 106, 43,
        26, 120, 35, 44, 137, 243, 184, 160, 251, 223, 0, 93, 14, 0, 0, 0, 0, 62, 149, 186, 128>>
  """
  def serialize(%__MODULE__{to: to, amount: amount}), do: <<to::binary, amount::64>>

  @spec to_map(uco_transfer :: t()) :: map()
  def to_map(%__MODULE__{to: to, amount: amount}), do: %{to: Base.encode16(to), amount: amount}
end
