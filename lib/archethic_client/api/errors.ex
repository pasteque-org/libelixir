defmodule ArchethicClient.APIError do
  @moduledoc """
  Represent an error from the API module
  """

  defexception [:request, :message]
end

defmodule ArchethicClient.GraphqlError do
  @moduledoc """
  Represent an error returned by the Archethic network using Graphql request
  """

  defexception [:location, :message]
end

defmodule ArchethicClient.RPCError do
  @moduledoc """
  Represent an error returned by the Archethic network using RPC request
  """

  defexception [:message, :code, :data]
end

defmodule ArchethicClient.ValidationError do
  @moduledoc """
  Represent an error returned by the Archethic network when validating a transaction
  """
  defexception [:address, :context, :message, :code, :data]

  def message(%__MODULE__{context: context, message: message, data: data}) do
    messages = stringify_data(data)
    Enum.join([context, message | messages], ": ")
  end

  defp stringify_data(data, acc \\ [])
  defp stringify_data(data, acc) when is_binary(data), do: [data | acc]

  defp stringify_data(%{message: message, data: data}, acc) when is_binary(message),
    do: stringify_data(data, [message | acc])

  defp stringify_data(_data, acc), do: Enum.reverse(acc)

  @doc """
  Transform a map to a validation error exception
  """
  @spec from_map(map :: map()) :: Exception.t()
  def from_map(%{
        "address" => address,
        "context" => context,
        "error" => %{"code" => code, "message" => message, "data" => data}
      }),
      do: %__MODULE__{address: address, context: context, code: code, message: message, data: data}
end

defmodule ArchethicClient.RequestError do
  @moduledoc """
  Represent an error returned by the Archethic network
  """

  # Inspired by Plug.Conn.Status
  # https://github.com/elixir-plug/plug/blob/main/lib/plug/conn/status.ex
  @statuses %{
    100 => "Continue",
    101 => "Switching Protocols",
    102 => "Processing",
    103 => "Early Hints",
    200 => "OK",
    201 => "Created",
    202 => "Accepted",
    203 => "Non-Authoritative Information",
    204 => "No Content",
    205 => "Reset Content",
    206 => "Partial Content",
    207 => "Multi-Status",
    208 => "Already Reported",
    226 => "IM Used",
    300 => "Multiple Choices",
    301 => "Moved Permanently",
    302 => "Found",
    303 => "See Other",
    304 => "Not Modified",
    305 => "Use Proxy",
    306 => "Switch Proxy",
    307 => "Temporary Redirect",
    308 => "Permanent Redirect",
    400 => "Bad Request",
    401 => "Unauthorized",
    402 => "Payment Required",
    403 => "Forbidden",
    404 => "Not Found",
    405 => "Method Not Allowed",
    406 => "Not Acceptable",
    407 => "Proxy Authentication Required",
    408 => "Request Timeout",
    409 => "Conflict",
    410 => "Gone",
    411 => "Length Required",
    412 => "Precondition Failed",
    413 => "Request Entity Too Large",
    414 => "Request-URI Too Long",
    415 => "Unsupported Media Type",
    416 => "Requested Range Not Satisfiable",
    417 => "Expectation Failed",
    418 => "I'm a teapot",
    421 => "Misdirected Request",
    422 => "Unprocessable Entity",
    423 => "Locked",
    424 => "Failed Dependency",
    425 => "Too Early",
    426 => "Upgrade Required",
    428 => "Precondition Required",
    429 => "Too Many Requests",
    431 => "Request Header Fields Too Large",
    451 => "Unavailable For Legal Reasons",
    500 => "Internal Server Error",
    501 => "Not Implemented",
    502 => "Bad Gateway",
    503 => "Service Unavailable",
    504 => "Gateway Timeout",
    505 => "HTTP Version Not Supported",
    506 => "Variant Also Negotiates",
    507 => "Insufficient Storage",
    508 => "Loop Detected",
    510 => "Not Extended",
    511 => "Network Authentication Required"
  }

  defexception [:http_status, :body]

  @spec message(exception :: Exception.t()) :: message :: String.t()
  def message(%__MODULE__{http_status: status, body: ""}), do: Map.get(@statuses, status, "Unknown http status error")

  def message(%__MODULE__{body: body}) when is_binary(body), do: body
  def message(%__MODULE__{body: %{"error" => error}}) when is_binary(error), do: error

  def message(%__MODULE__{body: %{"error" => %{"message" => message}}}) when is_binary(message), do: message
end
