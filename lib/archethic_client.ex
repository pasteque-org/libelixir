defmodule ArchethicClient do
  @moduledoc """
  Documentation for `ArchethicClient`.
  """

  alias ArchethicClient.API
  alias ArchethicClient.Request

  @doc """
  Send a request to Archethic network
  """
  @spec request(request :: Request.t(), opts :: API.request_opts()) ::
          {:ok, term()} | {:error, reason :: :subscription | term()}
  defdelegate request(request, opts \\ []), to: API

  @doc """
  Same as request/2 but raise on error
  """
  @spec request!(request :: Request.t(), opts :: API.request_opts()) :: term()
  defdelegate request!(request, opts \\ []), to: API

  @doc """
  Batch multiple Request into a single request per Request type
  It keeps the same order as the request list provided
  """
  @spec batch_requests(requests :: list(Request.t()), opts :: API.request_opts()) ::
          list({:ok, term()} | {:error, Exception.t()})
  defdelegate batch_requests(requests, opts \\ []), to: API

  @doc """
  Same as batch_requests/2 but raise on error
  """
  @spec batch_requests!(requests :: list(Request.t()), opts :: API.request_opts()) :: list(term())
  defdelegate batch_requests!(requests, opts \\ []), to: API
end
