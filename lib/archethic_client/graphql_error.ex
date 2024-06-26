defmodule ArchethicClient.GraphqlError do
  @moduledoc """
  Represent an error returned by the Archethic network using Graphql request
  """

  defexception [:location, :message]
end
