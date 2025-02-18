defmodule ArchethicClient.APITest do
  @moduledoc """
  Test module to mock Req request
  """
  alias ArchethicClient.Crypto

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

  @doc """
  Return a random address and format it
  """
  @spec random_address(format :: :binary | :hex) :: Crypto.address() | Crypto.hex_address()
  def random_address(format \\ :binary) when format in [:binary, :hex] do
    address = <<0::16, :crypto.strong_rand_bytes(32)::binary>>
    if format == :hex, do: Base.encode16(address), else: address
  end
end
