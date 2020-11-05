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

---

## Add First Node
### Initialize
```
$ mkdir -p qdata/node-1/geth
$ geth --datadir qdata/node-1 account new
```

Leave the password blank. This will output:

```
...
Your new key was generated

Public address of the key:   0xee80b5e9F3b652084aebff39656EeFd10cb5A259
...
```

Next, create the genesis file:

```
$ cp config/genesis.json.example qdata/genesis.json
```

Replace the first `alloc` address with the address generated in the previous step.

Next, generate the nodekey
```
$ bootnode --genkey=qdata/node-1/geth/nodekey
$ bootnode --nodekey=qdata/node-1/geth/nodekey --writeaddress > qdata/node-1/enode
```

Display enode id of the new node:
```
$ cat qdata/node-1/enode
```

Next, create the `static-nodes.json` and `permissioned-nodes.json` files:

```
$ cp config/static-nodes.json.example qdata/node-1/static-nodes.json
$ cp config/permissioned-nodes.json.example qdata/node-1/permissioned-nodes.json
```

Replace the enodeID with the output in the previous step.

Next, initialize the new node:

```
$ geth --datadir qdata/node-1 init qdata/genesis.json
```

### Start

```
$ scripts/start.sh node-1
```

Here are the ports we use:
- `raftport`: 60000
- `rpcport`: 32000
- `node port`: 31000

### Deploy Permissioning Contracts

In this tutorial, we just use the pre-built contracts that locates at `config`:

```
$ cp -r config/permissioning_example qdata/permissioning
```

The deployment is a bit handy. Let's do it one by one.

#### 1. Upgradable Contract
In PermissionUpgradable contract, replace the argument of `simpleContract.new` with the address of node 1 account.

Then deploy permissionUpgradable contract:

```
$ scripts/deploy-contract.sh qdata/permissioning/deploy-PermissionsUpgradable.js
```

#### 2. Manager Contracts
In the `*-manager` contracts, replace the argument of `simpleContract.new` with the address of upgradable contract.

Then deploy:

```
$ scripts/deploy-contract.sh qdata/permissioning/deploy-OrgManager.js
$ scripts/deploy-contract.sh qdata/permissioning/deploy-RoleManager.js
$ scripts/deploy-contract.sh qdata/permissioning/deploy-AccountManager.js
$ scripts/deploy-contract.sh qdata/permissioning/deploy-VoterManager.js
$ scripts/deploy-contract.sh qdata/permissioning/deploy-NodeManager.js
$ scripts/deploy-contract.sh qdata/permissioning/deploy-PermissionsInterface.js
```

#### 3. Implementation Contract
- In PermissionImplementation contract, replace the arguments of `simpleContract.new` with the contract addresses of upgradeContract, orgManager, roleManager, accountManager, voteManager, and nodeManager, in order.

```
$ scripts/deploy-contract.sh qdata/permissioning/deploy-PermissionsImplementation.js
```

#### 4. Initialize Permissioning Contracts
In `load-PermissionUpgradable.js`, replace the addresses with the output of previous steps then initialize:

```
$ scripts/permission-init.sh
```

#### 5. Config `permission-nodes.json`
Create the permissioning config file:
```
$ cp config/permission-config.json.example qdata/node-1/permission-config.json
```

In this step, we use the pre-built permissioning contracts to deploy and replace the address listed in `permission-config.json` with the output addresses of the following commands:

Also, replace `accounts` with the node-1 account address.

### Restart
```
$ scripts/stop.sh
$ scripts/start.sh node-1
```

---

## Add an Additional Node
In this turorial, we need to interact with permissioning contracts to grant access to the new node.

### Initialize
```
$ mkdir -p qdata/node-2/geth
$ geth --datadir qdata/node-2 account new
```

Leave the password blank. This will output:

```
...
Your new key was generated

Public address of the key:   0xee80b5e9F3b652084aebff39656EeFd10cb5A259
...
```

<!-- Replace the second `alloc` address with the address generated in the previous step. -->

Next, generate the nodekey
```
$ bootnode --genkey=qdata/node-2/geth/nodekey
$ bootnode --nodekey=qdata/node-2/geth/nodekey --writeaddress > qdata/node-2/enode
```

Display enode id of the new node:
```
$ cat qdata/node-2/enode
```

Next, copy the `static-nodes.json`, `permissioned-nodes.json` and `permission-config.json` files:

```
$ cp qdata/node-1/static-nodes.json qdata/node-2
$ cp qdata/node-1/permissioned-nodes.json qdata/node-2/permissioned-nodes.json
$ cp qdata/node-1/permission-config.json qdata/node-2/permission-config.json
```

In `static-nodes.json` and `permissioned-nodes.json`, add the enodeID of `node-2` with the output in the previous step.

Next, initialize the new node:

```
$ geth --datadir qdata/node-2 init qdata/genesis.json
```

### Perform `addNode` via Permissioning Contract
In this step, we use this [postman API collection](https://www.getpostman.com/collections/0bb48d1645a73e275666) to perform `addNode`:

```
curl --location --request POST 'http://localhost:32000' \
--header 'Content-Type: application/json' \
--data-raw '{
    "jsonrpc": "2.0",
    "method": "quorumPermission_addNode",
    "params": [
        "foo",
        "enode://73e09e3a5712af82b7a6cec438381f147e7c7fbbffe8134f4f1b35829c3c5965ae86bce050d73edac25d7c5d34f822c9a4d3eff937f0c17a07b1a94dd8f92a29@127.0.0.1:31001?discport=0&raftport=60001",
        {
            "from": "0xf156AeD1Fd47584BA462f198A88f25e1e9b26175"
        }
    ],
    "id": 10
}'
```

After `addNode`, we can use `getOrgDetails` to check if `node-2` is in the node list:
```
curl --location --request POST 'http://localhost:32000' \
--header 'Content-Type: application/json' \
--data-raw '{"jsonrpc":"2.0","method":"quorumPermission_getOrgDetails","params":["foo"],"id":10}'
```

This should return the following results:
```
{
    "jsonrpc": "2.0",
    "id": 10,
    "result": {
        "nodeList": [
            {
                "orgId": "foo",
                "url": "enode://5aac4c201cf16709eead71a0b3b9623899ae4cb6a5f51fac870d6f46455f2756996daa49dfcf9604014e469b1c38416baa7c879355c77cb29b9ab5c4865f44e7@127.0.0.1:31000?discport=0&raftport=60000",
                "status": 2
            },
            {
                "orgId": "foo",
                "url": "enode://73e09e3a5712af82b7a6cec438381f147e7c7fbbffe8134f4f1b35829c3c5965ae86bce050d73edac25d7c5d34f822c9a4d3eff937f0c17a07b1a94dd8f92a29@127.0.0.1:31001?discport=0&raftport=60001",
                "status": 2
            }
        ],
        ...
    }
}
```

Next, login to the `node-1` console to `addPeer`. **This step is essential otherwise `node-1` will not be able to connect to `node-2`**.

```
$ geth attach qdata/node-1/geth.ipc
> raft.addPeer("enode://73e09e3a5712af82b7a6cec438381f147e7c7fbbffe8134f4f1b35829c3c5965ae86bce050d73edac25d7c5d34f822c9a4d3eff937f0c17a07b1a94dd8f92a29@127.0.0.1:31001?discport=0&raftport=60001")
```

### Start

```
$ scripts/start.sh node-2
```

Here are the ports we use:
- `raftport`: 60001
- `rpcport`: 32001
- `node port`: 31001

### Run a script
Now we can send a transction to the permissioned network. Ideally we should be able to get this transaction receipt in both `node-1` and `node-2`:

```
$ scripts/run.sh contracts/public-contracts.js
Contract transaction send: TransactionHash: 0xc98d304b2fd7fd6889469df284b2b520f50f6fa926d77f7a05ac5c7e71eb43e2 waiting to be mined...
true
```
