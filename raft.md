# Start a Quorum Network with Raft Consensus
## Add First Node
### Initialize
First, reset the environmant:
```
$ scripts/reset.sh
```

Then create new account:
```
$ mkdir -p qdata/node-raft-1/geth
$ geth --datadir qdata/node-raft-1 account new
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
$ cp config/genesis.json.example qdata/node-raft-1/genesis.json
```

Replace the first `alloc` address with the address generated in the previous step.

Next, generate the nodekey:
```
$ bootnode --genkey=qdata/node-raft-1/geth/nodekey
$ bootnode --nodekey=qdata/node-raft-1/geth/nodekey --writeaddress > qdata/node-raft-1/enode
```

Display enode id of the new node:
```
$ cat qdata/node-raft-1/enode
```

Next, create the `static-nodes.json` and `permissioned-nodes.json` files:

```
$ cp config/static-nodes.json.example qdata/node-raft-1/static-nodes.json
$ cp config/permissioned-nodes.json.example qdata/node-raft-1/permissioned-nodes.json
```

Replace the enodeID with the output in the previous step.

Next, initialize the new node:

```
$ geth --datadir qdata/node-raft-1 init qdata/node-raft-1/genesis.json
```

### Start
Here are the ports we use:
- `raftport`: 60000
- `rpcport`: 32000
- `node port`: 31000

```
$ scripts/start-quorum.sh node-raft-1 raft
```

### Deploy Permissioning Contracts
In this tutorial, we just use the pre-built contracts that locates at `config`:

```
$ cp -r config/permissioning_example qdata/permissioning
```

The deployment is a bit handy. Let's do it one by one.

#### 1. Upgradable Contract
In PermissionUpgradable contract, replace the argument of `simpleContract.new` with the address of node 1 account.

Then deploy:

```
$ scripts/deploy-contract.sh qdata/permissioning/deploy-PermissionsUpgradable.js node-raft-1
```

#### 2. Manager Contracts
In the `*-manager` contracts, replace the argument of `simpleContract.new` with the address of upgradable contract.

Then deploy:

```
$ scripts/deploy-contract.sh qdata/permissioning/deploy-OrgManager.js node-raft-1
$ scripts/deploy-contract.sh qdata/permissioning/deploy-RoleManager.js node-raft-1
$ scripts/deploy-contract.sh qdata/permissioning/deploy-AccountManager.js node-raft-1
$ scripts/deploy-contract.sh qdata/permissioning/deploy-VoterManager.js node-raft-1
$ scripts/deploy-contract.sh qdata/permissioning/deploy-NodeManager.js node-raft-1
$ scripts/deploy-contract.sh qdata/permissioning/deploy-PermissionsInterface.js node-raft-1
```

#### 3. Implementation Contract
In PermissionImplementation contract, replace the arguments of `simpleContract.new` with the contract addresses of upgradeContract, orgManager, roleManager, accountManager, voteManager, and nodeManager, in order.

Then deploy:

```
$ scripts/deploy-contract.sh qdata/permissioning/deploy-PermissionsImplementation.js node-raft-1
```

#### 4. Initialize Permissioning Contracts
In `load-PermissionUpgradable.js`, replace the addresses with the output of previous steps then initialize:

```
$ scripts/permission-init.sh node-raft-1
```

#### 5. Config `permission-config.json`
Create the permissioning config file:

```
$ cp config/permission-config.json.example qdata/node-raft-1/permission-config.json
```

Replace the address listed in `permission-config.json` with the contract addresses above and `accounts` with the `node-raft-1` account address.

### Restart
```
$ scripts/stop-quorum.sh
$ scripts/start-quorum.sh node-raft-1 raft
```

---

## Add an Additional Node
In this turorial, we need to interact with permissioning contracts to grant access to the new node.

### Initialize
```
$ mkdir -p qdata/node-raft-2/geth
$ geth --datadir qdata/node-raft-2 account new
```

Leave the password blank. This will output:

```
...
Your new key was generated

Public address of the key:   0xee80b5e9F3b652084aebff39656EeFd10cb5A259
...
```

Next, generate the nodekey:
```
$ bootnode --genkey=qdata/node-raft-2/geth/nodekey
$ bootnode --nodekey=qdata/node-raft-2/geth/nodekey --writeaddress > qdata/node-raft-2/enode
```

Display enode id of the new node:
```
$ cat qdata/node-raft-2/enode
```

Next, copy the `genesis.json`, `static-nodes.json`, `permissioned-nodes.json` and `permission-config.json` files:

```
$ cp qdata/node-raft-1/genesis.json qdata/node-raft-2
$ cp qdata/node-raft-1/static-nodes.json qdata/node-raft-2
$ cp qdata/node-raft-1/permissioned-nodes.json qdata/node-raft-2/permissioned-nodes.json
$ cp qdata/node-raft-1/permission-config.json qdata/node-raft-2/permission-config.json
```

In `static-nodes.json` and `permissioned-nodes.json`, add the enodeID of `node-raft-2` with the output in the previous step.

Next, initialize the new node:

```
$ geth --datadir qdata/node-raft-2 init qdata/node-raft-2/genesis.json
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

After `addNode`, we can use `getOrgDetails` to check if `node-raft-2` is in the node list:
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

Next, login to the `node-raft-1` console to `addPeer`. **This step is essential otherwise `node-raft-1` will not be able to connect to `node-raft-2`**:

```
$ geth attach qdata/node-raft-1/geth.ipc
> raft.addPeer("enode://73e09e3a5712af82b7a6cec438381f147e7c7fbbffe8134f4f1b35829c3c5965ae86bce050d73edac25d7c5d34f822c9a4d3eff937f0c17a07b1a94dd8f92a29@127.0.0.1:31001?discport=0&raftport=60001")
```

### Start

```
$ scripts/start-quorum.sh node-raft-2
```

Here are the ports we use:
- `raftport`: 60001
- `rpcport`: 32001
- `node port`: 31001

### Run a script
Now we can send a transction to the permissioned network. Ideally we should be able to get this transaction receipt in both `node-raft-1` and `node-raft-2`:

```
$ scripts/run.sh contracts/public-contract.js node-raft-1
Contract transaction send: TransactionHash: 0xc98d304b2fd7fd6889469df284b2b520f50f6fa926d77f7a05ac5c7e71eb43e2 waiting to be mined...
true
```

---

## Support Private Transaction
In order to support private transaction in Quorum, a Private Transaction Manager needs to be running. Here we use Tessera, which is one of the few PTM implementations.

### Install Tessera and jenv
Tessera is developed in Java. To install, let's download the JAR file from [here](https://github.com/ConsenSys/tessera/releases/tag/tessera-1.0.0) and then move the JAR file to `quorum-sandbox` repo:

```
$ mkdir tessera
$ mv ~/Downloads/tessera-app-1.0.0-app.jar ./tessera
```

Here we use Tessera v1.0.0, which requires java 11.

First, make sure you have Java 11 installed. If you have multiple Java versions installed, use [jenv](https://github.com/jenv/jenv) to switch to Java 11:

```
$ jenv add /Library/Java/JavaVirtualMachines/jdk-11.0.8.jdk/Contents/Home       
$ jenv global 11
$ jenv exec java -version
java version "11.0.8" 2020-07-14 LTS
Java(TM) SE Runtime Environment 18.9 (build 11.0.8+10-LTS)
Java HotSpot(TM) 64-Bit Server VM 18.9 (build 11.0.8+10-LTS, mixed mode)
```

### Initialize
First, create Tessera node folder and generate new key:
```
$ mkdir -p tdata/node-raft-1
$ cd tdata/node-raft-1
$ jenv exec java -jar ../../tessera/tessera-app-1.0.0-app.jar -keygen -filename node-raft-1
Enter a password if you want to lock the private key or leave blank

Please re-enter the password (or lack of) to confirm

2020-11-09 16:42:32.904 [main] INFO  com.quorum.tessera.nacl.jnacl.Jnacl - Generating new keypair...
2020-11-09 16:42:32.935 [main] INFO  com.quorum.tessera.nacl.jnacl.Jnacl - Generated new key pair with public key PublicKey[PhcCsV13hZ4wX6DDb3DLhE7DJI1RGkL+g32ERy6I7nE=]
2020-11-09 16:42:33.725 [main] INFO  c.q.t.k.generation.FileKeyGenerator - Saved public key to /yourpath/quorum-sandbox/tdata/node-raft-1/node-raft-1.pub
2020-11-09 16:42:33.726 [main] INFO  c.q.t.k.generation.FileKeyGenerator - Saved private key to /yourpath/quorum-sandbox/tdata/node-raft-1/node-raft-1.key
```

Next, create the config file:

```
$ cd ../..
$ cp config/tessera-config.json.example tdata/node-raft-1/config.json
```

Replace every `yourpath` with the path of your `quorum-sandbox` folder.

If you started 2 nodes, repeat above commands for `node-raft-2`:

```
$ mkdir -p tdata/node-raft-2
$ cd tdata/node-raft-2
$ jenv exec java -jar ../../tessera/tessera-app-1.0.0-app.jar -keygen -filename node-raft-2
Enter a password if you want to lock the private key or leave blank

Please re-enter the password (or lack of) to confirm

2020-11-09 16:42:32.904 [main] INFO  com.quorum.tessera.nacl.jnacl.Jnacl - Generating new keypair...
2020-11-09 16:42:32.935 [main] INFO  com.quorum.tessera.nacl.jnacl.Jnacl - Generated new key pair with public key PublicKey[PhcCsV13hZ4wX6DDb3DLhE7DJI1RGkL+g32ERy6I7nE=]
2020-11-09 16:42:33.725 [main] INFO  c.q.t.k.generation.FileKeyGenerator - Saved public key to /yourpath/quorum-sandbox/tdata/node-raft-2/node-raft-2.pub
2020-11-09 16:42:33.726 [main] INFO  c.q.t.k.generation.FileKeyGenerator - Saved private key to /yourpath/quorum-sandbox/tdata/node-raft-2/node-raft-2.key
```
```
$ cd ../..
$ cp config/tessera-config.json.example tdata/node-raft-2/config.json
```

Replace every `yourpath` with the path of your `quorum-sandbox` folder and `node-raft-1` with `node-raft-1`.

### Start
Start Tessera:

```
$ scripts/start-teserra.sh node-raft-1
$ scripts/start-teserra.sh node-raft-2
```

### Restart Quorum
Next, restart Quorum:

```
$ scripts/stop-quorum.sh
$ scripts/start-quorum-private.sh node-raft-1
$ scripts/start-quorum-private.sh node-raft-2
```

### Run a Script
Use `private-contract.js` to test if the private transaction is applied. Before you run the script, replace the `privateFor` argument to the `node-raft-1.pub` or `node-raft-2.pub`:

```
$ scripts/run.sh contracts/private-contract.js node-raft-1
Contract transaction send: TransactionHash: 0x60a7fc1a49e2df19ebfee63c22f7563ec0b5346573032f07099699f8b62411a3 waiting to be mined...
true
```
