defmodule ArchethicClient.TransactionDataTest do
  use ExUnit.Case, async: true

  alias ArchethicClient.TransactionData
  alias ArchethicClient.TransactionData.Contract

  describe "set_contract/2" do
    test "sets a contract on an empty TransactionData struct" do
      initial_data = %TransactionData{}
      contract_to_set = %Contract{bytecode: <<1, 2>>, manifest: %{"version" => "1.0"}}
      updated_data = TransactionData.set_contract(initial_data, contract_to_set)

      assert updated_data.contract == contract_to_set
      # Ensure other fields remain default/empty
      assert updated_data.content == initial_data.content
      assert updated_data.ownerships == initial_data.ownerships
      assert updated_data.recipients == initial_data.recipients
      assert updated_data.ledger == initial_data.ledger
    end

    test "replaces an existing contract" do
      original_contract = %Contract{bytecode: <<0>>, manifest: %{"v" => "old"}}
      initial_data = %TransactionData{contract: original_contract, content: "test"}
      new_contract = %Contract{bytecode: <<1, 2>>, manifest: %{"v" => "new"}}

      updated_data = TransactionData.set_contract(initial_data, new_contract)

      assert updated_data.contract == new_contract
      # Ensure other fields are preserved
      assert updated_data.content == "test"
    end

    test "clears an existing contract by setting it to nil" do
      original_contract = %Contract{bytecode: <<0>>, manifest: %{"v" => "old"}}
      initial_data = %TransactionData{contract: original_contract, content: "test"}

      updated_data = TransactionData.set_contract(initial_data, nil)

      assert updated_data.contract == nil
      assert updated_data.content == "test"
    end

    test "sets contract to nil if it was already nil" do
      initial_data = %TransactionData{contract: nil, content: "test"}
      updated_data = TransactionData.set_contract(initial_data, nil)

      assert updated_data.contract == nil
      assert updated_data.content == "test"
    end
  end
end
