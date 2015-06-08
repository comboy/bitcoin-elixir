# Bitcoin

A Bitcoin protocol parser library and full node implementation written in Elixir.

Current Status: Not even beta quality. Unstable Interfaces.
Not recommended for any use except gross curiosity.

This is my first Elixir/OTP Project and your improvements and constructive criticisms are highly appreciated.

##Licence
See the LICENCE file in the project root.

##Contributing
Please fork this repository to your own account, create a feature/{short but descriptive name} branch on your own
repository and submit a pull request back to develop.

##Component Status

### It Works (sort of)

* Protocol Library
  * Message Interface
    * Message Header Parsing
    * Message Type Detection and Parsing
  * Common Structures
    * varint/varint[]
    * varstring/varstring[]
    * inventory vector
    * network address
    * txin/txout/outpoint
    * block header
  * Message Parsing (Individual Messages and their representations)
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
  * Message Emission
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
  * Peer Connectivity
    * Message Exchange / Configuration
