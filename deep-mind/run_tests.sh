#!/bin/bash -ex

/opt/bin/eiosio/bin/nodeos --data-dir `pwd` --config-dir `pwd` > output.log &

sleep 5

killall nodeos

diff reference.log output.log
