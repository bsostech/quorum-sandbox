#!/bin/bash

sleepTime=1

getContractAddress(){
    txid=$1
    x=$(geth attach ipc:$(pwd)/qdata/node-1/geth.ipc <<EOF
    var addr=eth.getTransactionReceipt("$txid").contractAddress;
    console.log("contarct address number is :["+addr+"]");
    exit;
EOF
    )
    contaddr=`echo $x| tr -s " "| cut -f2 -d "[" | cut -f1 -d"]"`
    echo $contaddr
}

file=$1
op=`./scripts/run.sh $file`
tx=`echo $op | head -1 | tr -s " "| cut -f5 -d " "`
sleep $sleepTime
contAddr=`getContractAddress $tx`
echo "$file Address: $contAddr"
