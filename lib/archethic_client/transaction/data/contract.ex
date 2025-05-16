defmodule ArchethicClient.TransactionData.Contract do
  @moduledoc """
  Represents the definition of a smart contract within a transaction.

  A contract is primarily defined by its:
  - `bytecode`: The compiled WebAssembly (WASM) code of the contract.
  - `manifest`: A map describing the contract's functions, state, and upgrade options (ABI).

  This module provides functions to serialize and deserialize contract data, as well as
  convert it to and from map representations.
  """
  alias ArchethicClient.Utils.TypedEncoding

  @enforce_keys [:bytecode, :manifest]
  defstruct [:bytecode, :manifest]

  @type t :: %__MODULE__{
          bytecode: binary(),
          manifest: map()
        }

  @doc """
  Serialize a contract
  """
  @spec serialize(contract :: t()) :: bitstring()
  def serialize(contract)

  def serialize(%__MODULE__{bytecode: bytecode, manifest: manifest}) do
    <<byte_size(bytecode)::32, bytecode::binary, TypedEncoding.serialize(manifest)::bitstring>>
  end

  @doc """
  Converts a `ArchethicClient.TransactionData.Contract` struct or nil into a map representation.

  If nil is provided, nil is returned.
  The bytecode is Base16 encoded in the resulting map.
  """
  @spec to_map(contract :: nil | t()) :: nil | map()
  def to_map(nil), do: nil

  def to_map(%__MODULE__{bytecode: bytecode, manifest: manifest}) do
    %{
      bytecode: Base.encode16(bytecode),
      manifest: manifest
    }
  end
end
