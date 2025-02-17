defmodule ArchethicClient.APITest do
  @moduledoc """
  Test module to mock Req request
  """

  @doc """
  Stub request
  """
  @spec stub(callback :: function()) :: :ok
  def stub(callback) do
    Req.Test.stub(__MODULE__, fn conn ->
      Plug.Conn.send_resp(conn, 200, :erlang.term_to_binary(callback))
    end)
  end

  def parse_resp({:data, data}, {req, resp}) do
    callback = :erlang.binary_to_term(data)

    body = req |> Req.Request.get_private(:archethic_client) |> create_resp_body(callback)

    resp = %Req.Response{resp | body: body}

    {:cont, {req, resp}}
  end

  defp create_resp_body(requests, callback) when is_list(requests), do: Enum.map(requests, &callback.(&1))
  defp create_resp_body(request, callback), do: callback.(request)
end
