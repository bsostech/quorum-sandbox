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

## Add New Node
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

## Start New Node

```
$ scripts/start.sh
```

Here are the ports we use:
- `raftport`: 60000
- `rpcport`: 32000
- `node port`: 31000

## Deploy Permissioning Contracts

In this tutorial, we just use the pre-built contracts that locates at `config`:

```
$ cp -r config/permissioning_example qdata/permissioning
```

The deployment is a bit handy. Let's do it one by one.

### 1. Upgradable Contract
In PermissionUpgradable contract, replace the argument of `simpleContract.new` with the address of node 1 account.

Then deploy permissionUpgradable contract:

```
$ scripts/deploy-contract.sh qdata/permissioning/deploy-PermissionsUpgradable.js
```

### 2. Manager Contracts
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

### 3. Implementation Contract
- In PermissionImplementation contract, replace the arguments of `simpleContract.new` with the contract addresses of upgradeContract, orgManager, roleManager, accountManager, voteManager, and nodeManager, in order.

```
$ scripts/deploy-contract.sh qdata/permissioning/deploy-PermissionsImplementation.js
```

### 4. Initialize
In `load-PermissionUpgradable.js`, replace the addresses with the output of previous steps then initialize:

```
$ scripts/permission-init.sh
```

### 5. Config
Create the permissioning config file:
```
$ cp config/permission-config.json.example qdata/node-1/permission-config.json
```

In this step, we use the pre-built permissioning contracts to deploy and replace the address listed in `permission-config.json` with the output addresses of the following commands:

Also, replace `accounts` with the node-1 account address.

## Restart
```
$ scripts/stop.sh
$ scripts/srart.sh
```

## Run script
```
$ scripts/run.sh contracts/public-contracts.js
```
