#!/bin/bash -ex

rm -rf blocks/ state/

EOS_CODEBASE=~/build/eos
$EOS_CODEBASE/build/programs/nodeos/nodeos --data-dir=`pwd`  --config-dir=`pwd` --genesis-json=`pwd`/genesis.json &
PID=$!

function shutdown {
    kill $PID
}
trap shutdown EXIT

sleep 1

eos-bios boot bootseq.yaml --reuse-genesis --api-url http://localhost:9898

export EOSC_GLOBAL_INSECURE_VAULT_PASSPHRASE=secure
export EOSC_GLOBAL_API_URL=http://localhost:9898

eosc transfer eosio battlefield1 100000 --memo "go habs go"

eosc tx create battlefield1 dbins '{"account": "battlefield1"}' -p battlefield1@active

sleep 0.6

eosc tx create battlefield1 dbupd '{"account": "battlefield1"}' -p battlefield1@active

sleep 0.6

eosc tx create battlefield1 dbrem '{"account": "battlefield1"}' -p battlefield1@active

sleep 0.6

eosc tx create battlefield1 dtrx '{"account": "battlefield1", "fail": false}' -p battlefield1@active
eosc tx create battlefield1 dtrxcancel '{"account": "battlefield1"}' -p battlefield1@active

sleep 0.6

eosc tx create battlefield1 dtrx '{"account": "battlefield1", "fail": true}' -p battlefield1@active || true

sleep 0.6

# TODO: provoke a `hard_fail` transaction.
# TODO: provode a `soft_fail` transaction
# TODO: provoke an `expired` transaction.

echo "Exiting in 1 sec"
sleep 1
