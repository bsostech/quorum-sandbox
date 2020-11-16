#!/bin/bash

node=$1

if [ "$1" != "node-raft-1" ] && [ "$1" != "node-raft-2" ] && [ "$1" != "node-ibft-1" ] && [ "$1" != "node-ibft-2" ]
then
    echo "Error: Use node-raft-1, node-raft-2, node-ibft-1 or node-ibft-2"
fi

jenv exec java -jar tessera/tessera-app-1.0.0-app.jar -configfile tdata/$node/config.json >> tdata/$node/tessera.log 2>&1 &
