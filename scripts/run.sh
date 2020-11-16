#!/bin/bash

export PATH=$(pwd)/bin:$PATH

if [ "$2" != "node-raft-1" ] && [ "$2" != "node-raft-2" ] && [ "$2" != "node-ibft-1" ] && [ "$2" != "node-ibft-2" ]
then
    echo "Error: Use node-raft-1, node-raft-2, node-ibft-1 or node-ibft-2"
    exit
fi

geth --exec "loadScript(\"$1\")" attach ipc:qdata/$2/geth.ipc
