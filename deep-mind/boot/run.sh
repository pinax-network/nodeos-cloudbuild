#!/bin/bash -ex

rm -rf blocks/ state/

EOS_CODEBASE=~/build/eos
$EOS_CODEBASE/build/programs/nodeos/nodeos --data-dir=`pwd`  --config-dir=`pwd` --genesis-json=`pwd`/genesis.json &

sleep 1

eos-bios boot bootseq.yaml --reuse-genesis --api-url http://localhost:9898

export EOSC_GLOBAL_INSECURE_VAULT_PASSPHRASE=secure
export EOSC_GLOBAL_API_URL=http://localhost:9898

eosc transfer eosio battlefield1 100000 --memo "go habs go"

eosc tx create battlefield1 dbins '{"account": "battlefield1"}' -p battlefield1@active

sleep 0.6

eosc tx create battlefield1 dbins '{"account": "battlefield1"}' -p battlefield1@active

sleep 0.6

killall nodeos
