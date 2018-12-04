#!/bin/bash -ex

# Through Docker:
#
#docker run -ti --rm --detach --name nodeos-bios \
#       -v `pwd`:/etc/nodeos -v /tmp/nodeos-data:/data \
#       -p 127.0.0.1:8888:8888 -p 127.0.0.1:9876:9876 \
#       gcr.io/eoscanada-shared-services/eosio-nodeos-prod:v1.1.1 \
#       /opt/eosio/bin/nodeos --data-dir=/data \
#                             --config-dir=/etc/nodeos \
#                             --genesis-json=/etc/nodeos/genesis.json

# Locally:
#
#~/build/eos/build/programs/nodeos/nodeos --data-dir=`pwd`  --config-dir=`pwd` --genesis-json=`pwd`/genesis.json
#
# or
#
#/opt/eosio/bin/nodeos --data-dir=`pwd`  --config-dir=`pwd` --genesis-json=`pwd`/genesis.json
#
