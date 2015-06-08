#Bitcoin-Ex (Bitcoin Elixir)

A Bitcoin protocol parser library and full node implementation written in Elixir.

Current Status: Not even beta quality. Unstable Interfaces.
Not recommended for any use except gross curiosity.

This is a weekend hack, your improvements and constructive criticisms are highly appreciated.

##Licence
See the LICENCE file in the project root.

##Contributing
Please fork this repository to your own account, create a feature/{short but descriptive name} branch on your own
repository and submit a pull request back to develop.

##Features (Planned)

* Complete Bitcoin Parsing Library
* Complete Bitcoin Node Implementation
  * OTP Clustering/Distribution Support for Non-Stop Operation including Hot Code Reloading w/o Node Restart in Production
  * Suitable for Elixir/Erlang Application Embedding (for creating a [Toshi](https://github.com/coinbase/toshi) compatible API or web interface for example)
  * Abstract Blockchain Bulk Data and Index Storage Backend Interface (Mnesia, Postgres, etc...)

##Feature Status (Current)

### It Works (sort of)

* Protocol Library
  * Message Interface
    * Message Header Parsing
    * Message Type Detection and Parsing
  * Common Structure Deserialisation
    * varint/varint[]
    * varstring/varstring[]
    * inventory vector
    * network address
    * txin/txout/outpoint
    * block header
  * Message Deserialisation (Individual Messages and their representations)
    * addr
    * alert
    * block
    * getaddr
    * getblocks
    * getdata
    * getheaders
    * headers
    * inv
    * notfound
    * ping
    * pong
    * reject
    * tx
    * version
* OTP Application / Full Node
  * Peer
    * Connection Pool/Acceptor and Handler
    * Discovery
      * Strategies
        * DNS

### Not Yet (In Progress)

* Protocol Library
  * High Level Domain Objects and Actor Representations
    * Peer
    * Blockchain
    * Block
    * Transaction Queues
  * Event Model
  * Logging Strategy
  * Common Structure Serialisation
    * varint/varint[]
    * varstring/varstring[]
    * inventory vector
    * network address
    * txin/txout/outpoint
    * block header  
  * Message Serialisation
    * addr
    * alert
    * block
    * getaddr
    * getblocks
    * getdata
    * getheaders
    * headers
    * inv
    * notfound
    * ping
    * pong
    * reject
    * tx
    * version
* OTP Application / Full Node
  * Server Layout and Deployment
  * Blockchain Bulk Storage and Index API
  * Transaction Script Engine
    * Script Parsing (Compression for Serialisation?)
    * Virtual Machine for Script Evaluation/Execution (base on GenServer and Callback State System for near-native speed execution of stack machines)
  * Peer Connectivity
    * Message Exchange / Configuration

### Compliance Tests Not Yet Passing but for which Compliance is a Goal

* TheBlueMatt's [regression test suite](https://github.com/TheBlueMatt/test-scripts)
