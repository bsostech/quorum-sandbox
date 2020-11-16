#!/bin/bash

export PATH=$(pwd)/bin:$PATH
sleepTime=2

getContractAddress(){
    txid=$1
    node=$2
    x=$(geth attach ipc:$(pwd)/qdata/$node/geth.ipc <<EOF
    var addr=eth.getTransactionReceipt("$txid").contractAddress;
    console.log("contarct address number is :["+addr+"]");
    exit;
EOF
    )
    contaddr=`echo $x| tr -s " "| cut -f2 -d "[" | cut -f1 -d"]"`
    echo $contaddr
}

file=$1
node=$2

if [ "$2" != "node-raft-1" ] && [ "$2" != "node-raft-2" ] && [ "$2" != "node-ibft-1" ] && [ "$2" != "node-ibft-2" ]
then
    echo "Error: Use node-raft-1, node-raft-2, node-ibft-1 or node-ibft-2"
    exit
fi

op=`./scripts/run.sh $file $node`
tx=`echo $op | head -1 | tr -s " "| cut -f5 -d " "`
sleep $sleepTime
contAddr=`getContractAddress $tx $node`
echo "$file Address: $contAddr"
