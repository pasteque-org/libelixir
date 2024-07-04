defmodule ArchethicClient.RequestHelper do
  @moduledoc """
  Helper to create common request or subscription
  """

  alias ArchethicClient.Crypto
  alias ArchethicClient.Graphql
  alias ArchethicClient.Request
  alias ArchethicClient.RPC
  alias ArchethicClient.Transaction

  @typedoc """
  Options for the contract_function_call Request.
  - resolve_last? => boolean to resolve the last transaction of the provided contract address (default: true)
  """
  @type contract_fun_opts :: [resolve_last?: boolean()]

  @doc """
  Returns a Request struct to get the balance of a chain
  """
  @spec get_balance(address :: Crypto.hex_address()) :: Request.t(Graphql)
  def get_balance(address) do
    %Graphql{
      name: "balance",
      args: [address: address],
      fields: [:uco, token: [:address, :amount, :tokenId]]
    }
  end

  @doc """
  Returns a Request struct to call a public function of a smart contract
  """
  @spec contract_function_call(
          address :: Crypto.hex_address(),
          function :: String.t(),
          args :: list(),
          opts :: contract_fun_opts()
        ) :: Request.t(RPC)
  def contract_function_call(address, function, args \\ [], opts \\ []) do
    Keyword.validate!(opts, [:request_last?])

    params = %{
      "contract" => address,
      "function" => function,
      "args" => args,
      "resolve_last" => Keyword.get(opts, :request_last?, true)
    }

    %RPC{method: "contract_fun", params: params}
  end

  @doc """
  Returns a Request struct to send a transaction
  """
  @spec send_transaction(transaction :: Transaction.t()) :: Request.t(RPC)
  def send_transaction(transaction),
    do: %RPC{method: "send_transaction", params: %{transaction: Transaction.to_map(transaction)}}

  @doc """
  Returns a Request to subscribe on transaction confirmed
  """
  @spec subscribe_transaction_confirmed(address :: Crypto.hex_address()) :: Request.t(Graphql)
  def subscribe_transaction_confirmed(address) do
    %Graphql{
      type: :subscription,
      name: "transactionConfirmed",
      args: [address: address],
      fields: [:address, :nbConfirmations, :maxConfirmations]
    }
  end

  @doc """
  Returns a Request to subscribe on transaction error
  """
  @spec subscribe_transaction_error(address :: Crypto.hex_address()) :: Request.t(Graphql)
  def subscribe_transaction_error(address) do
    %Graphql{
      type: :subscription,
      name: "transactionError",
      args: [address: address],
      fields: [:address, :context, error: [:code, :message, :data]]
    }
  end
end
