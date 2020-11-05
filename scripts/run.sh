#!/bin/bash

export PATH=$(pwd)/bin:$PATH

geth --exec "loadScript(\"$1\")" attach ipc:qdata/node-1/geth.ipc
