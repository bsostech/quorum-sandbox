#!/bin/bash
export PATH=$(pwd)/bin:$PATH

node=$1
raftport=
rpcport=
port=

if [ "$1" == "node-1" ]
then
    raftport=60000
    rpcport=32000
    port=31000
elif [ "$1" == "node-2" ]
then
    raftport=60001
    rpcport=32001
    port=31001
else
    echo "Error: Use node-1 or node-2"
fi

PRIVATE_CONFIG=ignore nohup \
geth --datadir qdata/$node --nodiscover --nousb --allow-insecure-unlock --verbosity 3 --networkid 10 \
--raft --raftblocktime 50 --rpc --rpccorsdomain=* --rpcvhosts=* --rpcaddr 0.0.0.0 \
--rpcapi admin,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft,quorumPermission,quorumExtension \
--emitcheckpoints --unlock 0 --password config/passwords.txt \
--permissioned --raftport $raftport --rpcport $rpcport --port $port 2>>qdata/$node/log &
