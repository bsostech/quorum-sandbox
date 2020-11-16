# Start a Quorum Network with IBFT Consensus
## Add First Node
### Initialize
First, reset the environmant:
```
$ scripts/reset.sh
```

Then create new folders:
```
$ mkdir -p qdata/node-ibft-1/geth
$ mkdir -p qdata/node-ibft-2/geth
$ mkdir -p qdata/node-ibft-3/geth
$ mkdir -p qdata/node-ibft-4/geth
```

Here, instead of generating the key and genesis file manually, we will use `istanbul` tool:
```
$ cd qdata/node-ibft-1
$ istanbul setup --num 4 --nodes --quorum --save --verbose
```

This command will generate `nodekey`, `genesis.json` and `static-nodes.json` files.

We need to move `nodekey` to the `geth` folder:
```
$ mv 0/nodekey geth/nodekey && rm -r 0
$ mv 1/nodekey ../node-ibft-2/geth/nodekey && rm -r 1
$ mv 2/nodekey ../node-ibft-3/geth/nodekey && rm -r 2
$ mv 3/nodekey ../node-ibft-4/geth/nodekey && rm -r 3

```

Next, create new accounts for each node:

```
$ cd ../..
$ geth --datadir qdata/node-ibft-1 account new
$ geth --datadir qdata/node-ibft-2 account new
$ geth --datadir qdata/node-ibft-3 account new
$ geth --datadir qdata/node-ibft-4 account new
```

Leave the password blank. This will output:

```
...
Your new key was generated

Public address of the key:   0xee80b5e9F3b652084aebff39656EeFd10cb5A259
...
```

Add all the generated address to the `alloc` in `genesis.json`.

One more thing: remember to change the `maxCodeSizeConfig` [from `0` to `35`](https://github.com/ConsenSys/quorum/issues/851#issuecomment-542478942) in `genesis.json`:
```
# genesis.json

{
    ...
    "config": {
        ...
        "maxCodeSizeConfig": [
            {
                "block": 0,
                "size": 35
            }
        ],
        ...
    }
}
```

Next, config the `static-nodes.json` ports to be in the range from `31000` to `31003`.

Then, create the `permissioned-nodes.json` file:

```
$ cp qdata/node-ibft-1/static-nodes.json qdata/node-ibft-1/permissioned-nodes.json
```

Finally, we need to create `static-node.json`, `permissioned-nodes.json` and `genesis.json` for the rest of the nodes:
```
$ cp qdata/node-ibft-1/static-nodes.json qdata/node-ibft-2 && cp qdata/node-ibft-1/permissioned-nodes.json qdata/node-ibft-2 && cp qdata/node-ibft-1/genesis.json qdata/node-ibft-2
$ cp qdata/node-ibft-1/static-nodes.json qdata/node-ibft-3 && cp qdata/node-ibft-1/permissioned-nodes.json qdata/node-ibft-3 && cp qdata/node-ibft-1/genesis.json qdata/node-ibft-3
$ cp qdata/node-ibft-1/static-nodes.json qdata/node-ibft-4 && cp qdata/node-ibft-1/permissioned-nodes.json qdata/node-ibft-4 && cp qdata/node-ibft-1/genesis.json qdata/node-ibft-4
```

Let's initialize all the nodes:

```
$ geth --datadir qdata/node-ibft-1 init qdata/node-ibft-1/genesis.json
$ geth --datadir qdata/node-ibft-2 init qdata/node-ibft-2/genesis.json
$ geth --datadir qdata/node-ibft-3 init qdata/node-ibft-3/genesis.json
$ geth --datadir qdata/node-ibft-4 init qdata/node-ibft-4/genesis.json
```

### Start
Here are the ports we use:
- `ibftport`: 60000
- `rpcport`: 32000
- `node port`: 31000

```
$ scripts/start-quorum.sh node-ibft-1 ibft
$ scripts/start-quorum.sh node-ibft-2 ibft
$ scripts/start-quorum.sh node-ibft-3 ibft
$ scripts/start-quorum.sh node-ibft-4 ibft
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
$ scripts/deploy-contract.sh qdata/permissioning/deploy-PermissionsUpgradable.js node-ibft-1
```

#### 2. Manager Contracts
In the `*-manager` contracts, replace the argument of `simpleContract.new` with the address of upgradable contract.

Then deploy:

```
$ scripts/deploy-contract.sh qdata/permissioning/deploy-OrgManager.js node-ibft-1
$ scripts/deploy-contract.sh qdata/permissioning/deploy-RoleManager.js node-ibft-1
$ scripts/deploy-contract.sh qdata/permissioning/deploy-AccountManager.js node-ibft-1
$ scripts/deploy-contract.sh qdata/permissioning/deploy-VoterManager.js node-ibft-1
$ scripts/deploy-contract.sh qdata/permissioning/deploy-NodeManager.js node-ibft-1
$ scripts/deploy-contract.sh qdata/permissioning/deploy-PermissionsInterface.js node-ibft-1
```

#### 3. Implementation Contract
In PermissionImplementation contract, replace the arguments of `simpleContract.new` with the contract addresses of upgradeContract, orgManager, roleManager, accountManager, voteManager, and nodeManager, in order.

Then deploy:

```
$ scripts/deploy-contract.sh qdata/permissioning/deploy-PermissionsImplementation.js node-ibft-1
```

#### 4. Initialize Permissioning Contracts
In `load-PermissionUpgradable.js`, replace the addresses with the output of previous steps then initialize:

```
$ scripts/permission-init.sh node-ibft-1
```

#### 5. Config `permission-config.json`
Create the permissioning config file:

```
$ cp config/permission-config.json.example qdata/node-ibft-1/permission-config.json
```

Replace the address listed in `permission-config.json` with the contract addresses above and `accounts` with the `node-ibft-1` account address.

Create `permission-config.json` for the rest of the nodes:
```
$ cp qdata/node-ibft-1/permission-config.json qdata/node-ibft-2 && cp qdata/node-ibft-1/permission-config.json qdata/node-ibft-3 && cp qdata/node-ibft-1/permission-config.json qdata/node-ibft-4
```
### Restart
```
$ scripts/stop-quorum.sh
$ scripts/start-quorum.sh node-ibft-1 ibft && scripts/start-quorum.sh node-ibft-2 ibft && scripts/start-quorum.sh node-ibft-3 ibft && scripts/start-quorum.sh node-ibft-4 ibft
```

---

## Add an Additional Node
In this turorial, we need to interact with permissioning contracts to grant access to the new node.

### Initialize
```
$ mkdir -p qdata/node-ibft-5/geth
$ geth --datadir qdata/node-ibft-5 account new
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
$ bootnode --genkey=qdata/node-ibft-5/geth/nodekey
$ bootnode --nodekey=qdata/node-ibft-5/geth/nodekey --writeaddress > qdata/node-ibft-5/enode
```

Display enode id of the new node:
```
$ cat qdata/node-ibft-5/enode
```

Next, copy the `genesis.json`, `static-nodes.json`, `permissioned-nodes.json` and `permission-config.json` files:

```
$ cp qdata/node-ibft-1/genesis.json qdata/node-ibft-5
$ cp qdata/node-ibft-1/static-nodes.json qdata/node-ibft-5
$ cp qdata/node-ibft-1/permissioned-nodes.json qdata/node-ibft-5/permissioned-nodes.json
$ cp qdata/node-ibft-1/permission-config.json qdata/node-ibft-5/permission-config.json
```

In `static-nodes.json` and `permissioned-nodes.json`, add the enodeID of `node-ibft-5` with the output in the previous step.

Next, initialize the new node:

```
$ geth --datadir qdata/node-ibft-5 init qdata/node-ibft-5/genesis.json
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
        "enode://73e09e3a5712af82b7a6cec438381f147e7c7fbbffe8134f4f1b35829c3c5965ae86bce050d73edac25d7c5d34f822c9a4d3eff937f0c17a07b1a94dd8f92a29@127.0.0.1:31001?discport=0&ibftport=60001",
        {
            "from": "0xf156AeD1Fd47584BA462f198A88f25e1e9b26175"
        }
    ],
    "id": 10
}'
```

After `addNode`, we can use `getOrgDetails` to check if `node-ibft-2` is in the node list:
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
                "url": "enode://5aac4c201cf16709eead71a0b3b9623899ae4cb6a5f51fac870d6f46455f2756996daa49dfcf9604014e469b1c38416baa7c879355c77cb29b9ab5c4865f44e7@127.0.0.1:31000?discport=0&ibftport=60000",
                "status": 2
            },
            {
                "orgId": "foo",
                "url": "enode://73e09e3a5712af82b7a6cec438381f147e7c7fbbffe8134f4f1b35829c3c5965ae86bce050d73edac25d7c5d34f822c9a4d3eff937f0c17a07b1a94dd8f92a29@127.0.0.1:31001?discport=0&ibftport=60001",
                "status": 2
            }
        ],
        ...
    }
}
```

Next, login to the `node-ibft-1`, `node-ibft-2` and `node-ibft-3` console to `propose`. There are 2 arguments of `propose` function: address **corresponding to the nodekey** of the validator, and a boolean value that is set to `true` to add new validator. **We need to propose in more than half of the node consoles otherwise `node-ibft-5` will not be able to be part of the IBFT consensus**:

```
$ geth attach qdata/node-ibft-1/geth.ipc
> istanbul.propose("0xAB09b5e9F3b652084aebff39656EeFd10cb5A258", true)
null
```
```
$ geth attach qdata/node-ibft-2/geth.ipc
> istanbul.propose("0xAB09b5e9F3b652084aebff39656EeFd10cb5A258", true)
null
```
```
$ geth attach qdata/node-ibft-3/geth.ipc
> istanbul.propose("0xAB09b5e9F3b652084aebff39656EeFd10cb5A258", true)
null
```

### Start

```
$ scripts/start-quorum.sh node-ibft-5 ibft
```

Here are the ports we use:
- `ibftport`: 60004
- `rpcport`: 32004
- `node port`: 31004

### Run a script
Now we can send a transction to the permissioned network. Ideally we should be able to get this transaction receipt in both `node-ibft-1` and `node-ibft-5`:

```
$ scripts/run.sh contracts/public-contract.js node-ibft-1
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
$ mkdir -p tdata/node-ibft-1
$ cd tdata/node-ibft-1
$ jenv exec java -jar ../../tessera/tessera-app-1.0.0-app.jar -keygen -filename node-ibft-1
Enter a password if you want to lock the private key or leave blank

Please re-enter the password (or lack of) to confirm

2020-11-09 16:42:32.904 [main] INFO  com.quorum.tessera.nacl.jnacl.Jnacl - Generating new keypair...
2020-11-09 16:42:32.935 [main] INFO  com.quorum.tessera.nacl.jnacl.Jnacl - Generated new key pair with public key PublicKey[PhcCsV13hZ4wX6DDb3DLhE7DJI1RGkL+g32ERy6I7nE=]
2020-11-09 16:42:33.725 [main] INFO  c.q.t.k.generation.FileKeyGenerator - Saved public key to /yourpath/quorum-sandbox/tdata/node-ibft-1/node-ibft-1.pub
2020-11-09 16:42:33.726 [main] INFO  c.q.t.k.generation.FileKeyGenerator - Saved private key to /yourpath/quorum-sandbox/tdata/node-ibft-1/node-ibft-1.key
```

Next, create the config file:

```
$ cd ../..
$ cp config/tessera-config.json.example tdata/node-ibft-1/config.json
```

Replace every `yourpath` with the path of your `quorum-sandbox` folder.

If you started 2 nodes, repeat above commands for `node-ibft-2`:

```
$ mkdir -p tdata/node-ibft-2
$ cd tdata/node-ibft-2
$ jenv exec java -jar ../../tessera/tessera-app-1.0.0-app.jar -keygen -filename node-ibft-2
Enter a password if you want to lock the private key or leave blank

Please re-enter the password (or lack of) to confirm

2020-11-09 16:42:32.904 [main] INFO  com.quorum.tessera.nacl.jnacl.Jnacl - Generating new keypair...
2020-11-09 16:42:32.935 [main] INFO  com.quorum.tessera.nacl.jnacl.Jnacl - Generated new key pair with public key PublicKey[PhcCsV13hZ4wX6DDb3DLhE7DJI1RGkL+g32ERy6I7nE=]
2020-11-09 16:42:33.725 [main] INFO  c.q.t.k.generation.FileKeyGenerator - Saved public key to /yourpath/quorum-sandbox/tdata/node-ibft-2/node-ibft-2.pub
2020-11-09 16:42:33.726 [main] INFO  c.q.t.k.generation.FileKeyGenerator - Saved private key to /yourpath/quorum-sandbox/tdata/node-ibft-2/node-ibft-2.key
```
```
$ cd ../..
$ cp config/tessera-config.json.example tdata/node-ibft-2/config.json
```

Replace every `yourpath` with the path of your `quorum-sandbox` folder and `node-ibft-1` with `node-ibft-1`.

### Start
Start Tessera:

```
$ scripts/start-teserra.sh node-ibft-1
$ scripts/start-teserra.sh node-ibft-2
```

### Restart Quorum
Next, restart Quorum:

```
$ scripts/stop-quorum.sh
$ scripts/start-quorum-private.sh node-ibft-1
$ scripts/start-quorum-private.sh node-ibft-2
```

### Run a Script
Use `private-contract.js` to test if the private transaction is applied. Before you run the script, replace the `privateFor` argument to the `node-ibft-1.pub` or `node-ibft-2.pub`:

```
$ scripts/run.sh contracts/private-contract.js
Contract transaction send: TransactionHash: 0x60a7fc1a49e2df19ebfee63c22f7563ec0b5346573032f07099699f8b62411a3 waiting to be mined...
true
```
