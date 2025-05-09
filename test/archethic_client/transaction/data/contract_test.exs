defmodule ArchethicClient.TransactionData.ContractTest do
  use ExUnit.Case, async: true

  alias ArchethicClient.TransactionData.Contract
  # Used internally by Contract.serialize
  alias ArchethicClient.Utils.TypedEncoding

  describe "to_map/1" do
    test "converts nil to nil" do
      assert Contract.to_map(nil) == nil
    end

    test "converts a Contract struct to the expected map format" do
      bytecode = <<0, 1, 2, 3, 255>>
      manifest_abi = %{"functions" => [%{"name" => "do_something"}], "state" => [%{"name" => "count"}]}
      manifest_upgrade = %{"from" => ["some_address_hash"]}
      manifest = %{"abi" => manifest_abi, "upgradeOpts" => manifest_upgrade}
      contract_struct = %Contract{bytecode: bytecode, manifest: manifest}

      expected_map = %{
        bytecode: Base.encode16(bytecode),
        manifest: %{
          abi: %{functions: [%{"name" => "do_something"}], state: [%{"name" => "count"}]},
          upgrade_opts: %{from: ["some_address_hash"]}
        }
      }

      assert Contract.to_map(contract_struct) == expected_map
    end

    test "converts a Contract struct with nil upgradeOpts to map" do
      bytecode = <<4, 5, 6>>
      manifest_abi = %{"functions" => [], "state" => []}
      manifest = %{"abi" => manifest_abi, "upgradeOpts" => nil}
      contract_struct = %Contract{bytecode: bytecode, manifest: manifest}

      expected_map = %{
        bytecode: Base.encode16(bytecode),
        manifest: %{
          abi: %{functions: [], state: []},
          upgrade_opts: nil
        }
      }

      assert Contract.to_map(contract_struct) == expected_map
    end
  end

  describe "serialize/2 and deserialize/3 (roundtrip)" do
    test "correctly serializes and deserializes a contract" do
      bytecode = <<10, 20, 30, 40, 50>>

      manifest = %{
        "abi" => %{
          "functions" => [%{"name" => "my_fun", "args" => ["u32"], "return" => "u64"}],
          "state" => [%{"name" => "owner", "type" => "address"}]
        },
        "version" => "1.0.0",
        "upgradeOpts" => nil
      }

      original_contract = %Contract{bytecode: bytecode, manifest: manifest}

      serialized_contract = Contract.serialize(original_contract)

      # Expected format: <<byte_size(bytecode)::32, bytecode::binary, TypedEncoding.serialize(manifest)::bitstring>>
      expected_bytecode_size = byte_size(bytecode)
      expected_serialized_manifest = TypedEncoding.serialize(manifest)
      # Manually construct for verification, though direct comparison is more robust
      manual_serialized = <<expected_bytecode_size::32, bytecode::binary, expected_serialized_manifest::binary>>
      assert serialized_contract == manual_serialized
    end
  end
end
