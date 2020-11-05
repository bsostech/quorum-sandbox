#!/bin/bash
export PATH=$(pwd)/bin:$PATH

PRIVATE_CONFIG=ignore nohup \
geth --datadir qdata/node-1 --nodiscover --nousb --allow-insecure-unlock --verbosity 3 --networkid 10 \
--raft --raftblocktime 50 --rpc --rpccorsdomain=* --rpcvhosts=* --rpcaddr 0.0.0.0 \
--rpcapi admin,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft,quorumPermission,quorumExtension \
--emitcheckpoints --unlock 0 --password config/passwords.txt \
--permissioned --raftport 60000 --rpcport 32000 --port 31000 2>>qdata/node-1/log &
