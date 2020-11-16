#!/bin/bash
export PATH=$(pwd)/bin:$PATH

node=$1
consensus=$2
raftport=
rpcport=
port=

if [ "$1" == "node-raft-1" ] || [ "$1" == "node-ibft-1" ]
then
    raftport=60000
    rpcport=32000
    port=31000
elif [ "$1" == "node-raft-2" ] || [ "$1" == "node-ibft-2" ]
then
    raftport=60001
    rpcport=32001
    port=31001
elif [ "$1" == "node-raft-3" ] || [ "$1" == "node-ibft-3" ]
then
    raftport=60002
    rpcport=32002
    port=31002
elif [ "$1" == "node-raft-4" ] || [ "$1" == "node-ibft-4" ]
then
    raftport=60003
    rpcport=32003
    port=31003
elif [ "$1" == "node-raft-5" ] || [ "$1" == "node-ibft-5" ]
then
    raftport=60004
    rpcport=32004
    port=31004
else
    echo "Error: Use 'node-raft-1', 'node-raft-2', 'node-ibft-1' or 'node-ibft-2'"
    exit
fi

if [ "$2" == "raft" ]
then
    PRIVATE_CONFIG=ignore nohup \
    geth --datadir qdata/$node --nodiscover --nousb --allow-insecure-unlock --verbosity 3 --networkid 10 \
    --raft --raftblocktime 50 --rpc --rpccorsdomain=* --rpcvhosts=* --rpcaddr 0.0.0.0 \
    --rpcapi admin,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft,quorumPermission,quorumExtension \
    --emitcheckpoints --unlock 0 --password config/passwords.txt \
    --permissioned --raftport $raftport --rpcport $rpcport --port $port 2>>qdata/$node/log &
elif [ "$2" == "ibft" ] 
then
    PRIVATE_CONFIG=ignore nohup \
    geth --datadir qdata/$node --nodiscover --nousb --allow-insecure-unlock --verbosity 5 --networkid 10 \
    --istanbul.blockperiod 1 --syncmode full --mine --minerthreads 1 --rpc --rpccorsdomain=* --rpcvhosts=* --rpcaddr 0.0.0.0 \
    --rpcapi admin,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul,quorumPermission,quorumExtension \
    --emitcheckpoints --unlock 0 --password config/passwords.txt \
    --permissioned --rpcport $rpcport --port $port 2>>qdata/$node/log &
else
    echo "Error: Use 'raft' or 'ibft'"
    exit
fi
