defmodule ArchethicClient.APIError do
  @moduledoc """
  Represent an error from the API module
  """

  defexception [:request, :message]
end
