#!/bin/bash

runInit(){
    x=$(geth attach ipc:$(pwd)/qdata/node-1/geth.ipc <<EOF
    loadScript("qdata/permissioning/load-PermissionsUpgradable.js");
    var tx = upgr.init(intr, impl, {from: eth.accounts[0], gas: 4500000});
    console.log("Init transaction id :["+tx+"]");
    exit;
EOF
    )
}

runInit
