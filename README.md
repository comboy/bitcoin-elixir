# Bitcoin-Ex (Bitcoin Elixir)

A Bitcoin protocol parser library and full node implementation written in Elixir.

Current Status: Not even beta quality. Unstable Interfaces.
Not recommended for any use except gross curiosity.

Your improvements and constructive criticisms are highly appreciated.

## Features (Planned)

* Complete Bitcoin Parsing Library
* Complete Bitcoin Node Implementation
  * OTP Clustering/Distribution Support for Non-Stop Operation including Hot Code Reloading w/o Node Restart in Production
  * Suitable for Elixir/Erlang Application Embedding (for creating a [Toshi](https://github.com/coinbase/toshi) compatible API or web interface for example)
  * Abstract Blockchain Bulk Data and Index Storage Backend Interface (Mnesia, Postgres, etc...)

### It Works (sort of)

* Protocol Library
  * Protocol messages parsing and serialization
  * Basic script interpreter (not yet passing full test suite)
* OTP Application / Full Node
  * DNS peer discovery
  * Establilishing connection with other peers
  * Fetching blockchain to a temporary memory storage

### Compliance Tests Not Yet Passing but for which Compliance is a Goal

* TheBlueMatt's [regression test suite](https://github.com/TheBlueMatt/test-scripts)

## Running the node

To start a node uncomment the following line in the dev.exs

    # config :bitcoin, :node, []

To avoid abusing the network you may want to only connect to your local node e.g.:

    config :bitcoin, :node, [
      connect: [{127.0.0.1}]
    ]

## Licence

See the LICENCE file in the project root.

## Contributing

Please fork this repository to your own account, create a feature/{short but descriptive name} branch on your own
repository and submit a pull request back to develop.



