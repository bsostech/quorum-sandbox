#!/bin/bash

node=$1

if [ "$1" != "node-1" ] && [ "$1" != "node-2" ]
then
    echo "Error: Use node-1 or node-2"
fi

jenv exec java -jar tessera/tessera-app-1.0.0-app.jar -configfile tdata/$node/config.json >> tdata/$node/tessera.log 2>&1 &
