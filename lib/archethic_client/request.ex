defprotocol ArchethicClient.Request do
  @moduledoc """
  Request protocol is responsible to determine the type of a request
  and to transform it into a HTTP / WS request body
  """

  @type t(_element) :: t()

  @doc """
  Returns the type of a request
  """
  @spec type(request :: t()) :: type :: atom()
  def type(request)

  @doc """
  Return true if the request is a subscription
  """
  @spec subscription?(request :: t()) :: boolean()
  def subscription?(request)

  @doc """
  Format the request for the body of an HTTP / WS request
  """
  @spec format_body(request :: t(), request_id :: term()) :: term()
  def format_body(request, request_id)

  @doc """
  Format the Request.Response struct
  """
  @spec format_response(request :: t(), request_id :: term(), response :: Req.Response.t()) ::
          {:ok, term()} | {:error, Exception.t()}
  def format_response(request, request_id, response)

  @doc """
  Generate a batch id based on an index
  """
  @spec request_id(request :: t(), index :: non_neg_integer()) :: term()
  def request_id(request, index)
end
