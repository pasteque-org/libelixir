defmodule ArchethicClient.Graphql do
  @moduledoc """
  TODO
  """

  alias ArchethicClient.Request

  @enforce_keys :name
  defstruct [:name, type: :query, args: [], fields: []]

  @type t :: %__MODULE__{
          type: :query | :subscription,
          name: String.t(),
          args: Keyword.t(),
          fields: list(field :: atom() | {type :: atom(), fields :: list()})
        }

  defimpl String.Chars, for: __MODULE__ do
    alias ArchethicClient.Graphql

    @spec to_string(struct :: Graphql.t()) :: String.t()
    def to_string(%Graphql{name: name, args: args, fields: fields}) do
      string_fields = stringify_fields(fields)

      case Enum.map_join(args, ", ", &stringify_arg/1) do
        "" -> "#{name}{#{string_fields}}"
        string_args -> "#{name}(#{string_args}){#{string_fields}}"
      end
    end

    defp stringify_arg({key, value}) when is_binary(value), do: "#{key}: \"#{value}\""
    defp stringify_arg({key, value}) when is_nil(value), do: "#{key}: null"
    defp stringify_arg({key, value}), do: "#{key}: #{value}"

    defp stringify_fields(fields, acc \\ "")
    defp stringify_fields([], acc), do: acc

    defp stringify_fields([field | rest], "") when is_atom(field), do: stringify_fields(rest, " #{field}")

    defp stringify_fields([field | rest], acc) when is_atom(field), do: stringify_fields(rest, "#{acc}, #{field}")

    defp stringify_fields([{type, fields} | rest], ""),
      do: stringify_fields(rest, " #{type} {#{stringify_fields(fields)}}")

    defp stringify_fields([{type, fields} | rest], acc),
      do: stringify_fields(rest, "#{acc}, #{type} {#{stringify_fields(fields)}}")
  end

  defimpl Request, for: ArchethicClient.Graphql do
    alias ArchethicClient.Graphql
    alias ArchethicClient.GraphqlError
    alias ArchethicClient.RequestError

    @spec type(request :: Graphql.t()) :: :graphql_query | :graphql_subscription
    def type(%Graphql{type: :query}), do: :graphql_query
    def type(%Graphql{type: :subscription}), do: :graphql_subscription

    @spec subscription?(request :: Graphql.t()) :: boolean()
    def subscription?(%Graphql{type: :subscription}), do: true
    def subscription?(_), do: false

    @spec request_id(request :: Graphql.t(), index :: non_neg_integer()) :: String.t()
    def request_id(_request, index), do: "graphql_#{index}"

    @spec format_body(request :: Graphql.t(), request_id :: String.t()) :: String.t()
    def format_body(%Graphql{} = request, request_id) do
      "#{request_id}: #{to_string(request)}"
    end

    @spec format_message(request :: Graphql.t(), request_id :: String.t(), message :: map()) :: term()
    def format_message(_, request_id, %{"data" => data}), do: Map.get(data, request_id)

    @spec format_response(
            request :: Graphql.t(),
            request_id :: String.t(),
            response :: Req.Response.t()
          ) :: {:ok, term()} | {:error, Exception.t()}
    def format_response(%Graphql{type: :query}, request_id, %Req.Response{status: 200, body: %{"data" => data} = body}) do
      errors = Map.get(body, "errors", [])

      case Enum.find(errors, fn %{"path" => path} -> Enum.member?(path, request_id) end) do
        nil ->
          {:ok, Map.get(data, request_id)}

        %{"locations" => [location | _], "message" => message} ->
          {:error, %GraphqlError{message: message, location: location}}
      end
    end

    def format_response(%Graphql{type: :subscription}, _request_id, %Req.Response{status: 200, body: body}),
      do: {:ok, body}

    def format_response(_, _, %Req.Response{status: status, body: body}) do
      {:error, %RequestError{http_status: status, body: body}}
    end
  end
end
