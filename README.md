# Quorum Sandbox
Quorum-sandbox is an experimental start-kit that is used to build a minimal quorum permissioned blockchain.

## Environment
- Quorum v2.7
- solc ~0.5.x

## Install
```
$ git clone git@github.com:bsostech/quorum-sandbox.git
$ cd quorum-sandbox
$ export PATH=$(pwd)/bin:$PATH
```

### Option 1: Use Built Binary
If you are using Mac OS, you can easily use the pre-built Quorum and Istanbul tool binary in the `bin` folder.

### Option 2: Build Quorum from Source
If the pre-built Quorum binary doesn't work in your case, please refer to [this document](https://docs.goquorum.consensys.net/en/stable/HowTo/GetStarted/Install/#from-source) to build from source.

For Istanbul tool, you can refer to [this document](https://docs.goquorum.consensys.net/en/stable/Tutorials/Creating-A-Network-From-Scratch/#goquorum-with-istanbul-bft-consensus).

## Start a Minimal Quorum Network
- [Start a Quorum Network with Raft Consensus](raft.md)
- [Start a Quorum Network with IBFT Consensus](ibft.md)
