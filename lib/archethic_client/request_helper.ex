defmodule ArchethicClient.RequestHelper do
  @moduledoc """
  Helper to create common request or subscription
  """

  alias ArchethicClient.Graphql
  alias ArchethicClient.Request
  alias ArchethicClient.RPC

  @typedoc """
  Options for the contract_function_call Request.
  - resolve_last? => boolean to resolve the last transaction of the provided contract address (default: true)
  """
  @type contract_fun_opts :: [resolve_last?: boolean()]

  @doc """
  Returns a Request struct to get the balance of a chain
  """
  @spec get_balance(address :: String.t()) :: Request.t(Graphql)
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
          address :: String.t(),
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
end
