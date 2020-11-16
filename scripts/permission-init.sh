#!/bin/bash

export PATH=$(pwd)/bin:$PATH

runInit(){
    node=$1
    x=$(geth attach ipc:$(pwd)/qdata/$1/geth.ipc <<EOF
    loadScript("qdata/permissioning/load-PermissionsUpgradable.js");
    var tx = upgr.init(intr, impl, {from: eth.accounts[0], gas: 4500000});
    console.log("Init transaction id :["+tx+"]");
    exit;
EOF
    )
}

if [ "$1" != "node-raft-1" ] && [ "$1" != "node-raft-2" ] && [ "$1" != "node-ibft-1" ] && [ "$1" != "node-ibft-2" ]
then
    echo "Error: Use node-raft-1, node-raft-2, node-ibft-1 or node-ibft-2"
    exit
fi

node=$1

runInit $node
