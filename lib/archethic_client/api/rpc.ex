defmodule ArchethicClient.RPC do
  @moduledoc """
  TODO
  """

  alias ArchethicClient.Request

  @enforce_keys :method
  defstruct [:method, params: []]

  @type t :: %__MODULE__{
          method: String.t(),
          params: map()
        }

  defimpl Request, for: ArchethicClient.RPC do
    alias ArchethicClient.RequestError
    alias ArchethicClient.RPC
    alias ArchethicClient.RPCError

    @spec type(request :: RPC.t()) :: :rpc
    def type(_), do: :rpc

    @spec subscription?(request :: RPC.t()) :: false
    def subscription?(_), do: false

    @spec request_id(request :: RPC.t(), index :: non_neg_integer()) :: String.t()
    def request_id(_, index), do: "rpc_#{index}"

    @spec format_body(request :: RPC.t(), request_id :: String.t()) :: map()
    def format_body(%RPC{method: method, params: params}, request_id),
      do: %{jsonrpc: "2.0", id: request_id, method: method, params: params}

    @spec format_message(request :: RPC.t(), request_id :: String.t(), message :: term()) :: term()
    def format_message(_, _, message), do: message

    @spec format_response(
            request :: RPC.t(),
            request_id :: String.t(),
            response :: Req.Response.t()
          ) :: {:ok, term()} | {:error, Exception.t()}
    def format_response(_, _, %Req.Response{status: 200, body: %{"result" => result}}), do: {:ok, result}

    def format_response(_, _, %Req.Response{status: 200, body: %{"error" => error}}) do
      rpc_error = %RPCError{
        message: Map.get(error, "message"),
        code: Map.get(error, "code"),
        data: Map.get(error, "data")
      }

      {:error, rpc_error}
    end

    def format_response(request, request_id, %Req.Response{status: 200, body: results} = response)
        when is_list(results) do
      request_response = Enum.find(results, nil, &match?(^request_id, &1["id"]))
      format_response(request, request_id, %Req.Response{response | body: request_response})
    end

    def format_response(_, _, %Req.Response{status: status, body: body}) do
      {:error, %RequestError{http_status: status, body: body}}
    end
  end
end
