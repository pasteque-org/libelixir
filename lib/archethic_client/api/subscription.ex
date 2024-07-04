defmodule ArchethicClient.Subscription do
  @moduledoc """
  GenServer to hold a subscription and transform AbsintheClient Message to
  ArchethicClient Message
  """

  use GenServer

  alias ArchethicClient.API.SubscriptionRegistry
  alias ArchethicClient.Request

  @enforce_keys [:ref, :message]
  defstruct [:ref, :message]

  def start_link(args) do
    ref = make_ref()

    case GenServer.start_link(__MODULE__, Keyword.put(args, :ref, ref), name: via_tuple(ref)) do
      {:ok, pid} -> {:ok, pid, ref}
      er -> er
    end
  end

  defp via_tuple(ref), do: {:via, Registry, {SubscriptionRegistry, ref}}

  def unsubscribe(%__MODULE__{ref: ref}), do: ref |> via_tuple() |> GenServer.cast(:unsubscribe)

  def init(args) do
    [ref: ref, req: req, request: request, request_id: request_id, send_to: send_to, ws: ws] =
      args |> Keyword.validate!([:ws, :req, :request, :request_id, :send_to, :ref]) |> Enum.sort()

    with {:ok, response} <- Req.request(req),
         {:ok, %AbsintheClient.Subscription{ref: sub_ref}} <- Request.format_response(request, request_id, response) do
      ws_ref = ws |> GenServer.whereis() |> Process.monitor()

      state = %{
        ws: ws,
        ref: ref,
        ws_ref: ws_ref,
        request: request,
        request_id: request_id,
        send_to: send_to,
        sub_ref: sub_ref
      }

      {:ok, state}
    else
      er -> {:stop, er}
    end
  end

  def handle_cast(:unsubscribe, %{ws: ws} = state) do
    AbsintheClient.WebSocket.clear_subscriptions(ws)
    {:stop, :shutdown, state}
  end

  def handle_info(
        %AbsintheClient.WebSocket.Message{ref: sub_ref, payload: payload},
        %{sub_ref: sub_ref, request: request, request_id: request_id, send_to: send_to, ref: ref} = state
      ) do
    res = Request.format_message(request, request_id, payload)
    send(send_to, %__MODULE__{ref: ref, message: res})

    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _, _}, %{ws_ref: ref} = state), do: {:stop, :shutdown, state}
end
