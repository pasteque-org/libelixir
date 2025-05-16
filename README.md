# ArchethicClient

ArchethicClient is an Elixir library for interacting with the [Archethic blockchain](https://www.archethic.net/). It provides a high-level, easy-to-use interface for sending requests, managing transactions, querying balances, and interacting with smart contracts on the Archethic network.

## Features

- Send single or batch requests to the Archethic network
- Query the balance of a genesis address
- Call public functions on smart contracts
- Retrieve the chain index for an address
- Send transactions with confirmation/error handling
- Synchronous API with both error-tuple and bang (`!`) variants
- Modular design for extensibility

## Installation

Add `archethic_client` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:archethic_client, "~> 0.1.1"}
  ]
end
```

Then run:

```sh
mix deps.get
```

## Usage

Import the main module in your Elixir code:

```elixir
alias ArchethicClient
```
## Tests

To run tests:

```sh
mix test
```

## Contributing

Contributions are welcome! Please open issues or submit pull requests on GitHub.

## License

This project is licensed under the terms of the LICENSE file in this repository.
