#!/bin/bash -ex

rm -rf blocks/ state/

$1 --data-dir=`pwd`  --config-dir=`pwd` --genesis-json=`pwd`/genesis.json &
PID=$!

function shutdown {
    kill $PID
}
trap shutdown EXIT

sleep 1

echo "Booting $1 node with smart contracts ..."
eos-bios boot bootseq.yaml --verbose --reuse-genesis --api-url http://localhost:9898

echo "Booting completed, launching test cases..."

export EOSC_GLOBAL_INSECURE_VAULT_PASSPHRASE=secure
export EOSC_GLOBAL_API_URL=http://localhost:9898

eosc transfer eosio battlefield1 100000 --memo "go habs go"

eosc system newaccount battlefield1 battlefield2 --auth-key EOS5MHPYyhjBjnQZejzZHqHewPWhGTfQWSVTWYEhDmJu4SXkzgweP --stake-cpu 1 --stake-net 1 --transfer

sleep 0.6

eosc tx create battlefield1 dbins '{"account": "battlefield1"}' -p battlefield1

sleep 0.6

eosc tx create battlefield1 dbupd '{"account": "battlefield1"}' -p battlefield1

sleep 0.6

eosc tx create battlefield1 dbrem '{"account": "battlefield1"}' -p battlefield1

sleep 0.6

# Account for commit d8fa7c07ee48e26a1b8e0cf7f098a6a02532922e, which shields from mis-used authority.
eosc system updateauth battlefield1 active owner battlefield_active_auth.yaml

sleep 0.6

eosc tx create battlefield1 dtrx '{"account": "battlefield1", "fail_now": false, "fail_later": false, "delay_sec": 1, "nonce": "1"}' -p battlefield1
eosc tx create battlefield1 dtrxcancel '{"account": "battlefield1"}' -p battlefield1

sleep 0.6

eosc tx create battlefield1 dtrx '{"account": "battlefield1", "fail_now": true, "fail_later": false, "delay_sec": 1, "nonce": "1"}' -p battlefield1 || true

sleep 0.6

# `send_deferred` with `replace_existing` enabled, to test `MODIFY` clauses.
eosc tx create battlefield1 dtrx '{"account": "battlefield1", "fail_now": false, "fail_later": false, "delay_sec": 1, "nonce": "1"}' -p battlefield1
eosc tx create battlefield1 dtrx '{"account": "battlefield1", "fail_now": false, "fail_later": false, "delay_sec": 1, "nonce": "2"}' -p battlefield1

sleep 0.6

eosc tx create battlefield1 dtrx '{"account": "battlefield1", "fail_now": false, "fail_later": true, "delay_sec": 1, "nonce": "1"}' -p battlefield1

echo Waiting for the transaction to fail...

sleep 1.1

eosc tx create battlefield1 dbinstwo '{"account": "battlefield1", "first": 100, "second": 101}' -p battlefield1
# This TX will do one DB_OPERATION for writing, and the second will fail. We want our instrumentation NOT to keep that DB_OPERATION.
eosc tx create --delay-sec=1 battlefield1 dbinstwo '{"account": "battlefield1", "first": 102, "second": 100}' -p battlefield1

echo Waiting for the transaction to fail, yet attempt to write to storage
sleep 1.1

# This is to see how the RAM_USAGE behaves, when a deferred hard_fails. Does it refund the deferred_trx_remove ? What about the other RAM tweaks? Any one them saved?
eosc tx create battlefield1 dbinstwo '{"account": "battlefield1", "first": 200, "second": 201}' -p battlefield1

sleep 0.6

echo "Create a delayed and cancel it with 'eosio:canceldelay'"
eosc tx create --delay-sec=3600 battlefield1 dbins '{"account": "battlefield1"}' -p battlefield1 --write-transaction /tmp/delayed.json
ID=`eosc tx id /tmp/delayed.json`
eosc tx push /tmp/delayed.json
eosc tx cancel battlefield1 $ID
rm /tmp/delayed.json || true

sleep 0.6

echo "Create auth structs, updateauth to create, updateauth to modify, deleteauth to test AUTH_OPs"

eosc system updateauth battlefield2 ops active EOS7f5watu1cLgth3ub1uAnsGkHq1F6PhauScBg6rJGUfe79MgG9Y # random key
sleep 0.6

eosc system updateauth battlefield2 ops active EOS5MHPYyhjBjnQZejzZHqHewPWhGTfQWSVTWYEhDmJu4SXkzgweP # back to safe key
sleep 0.6

eosc system deleteauth battlefield2 ops
sleep 0.6

# TODO: provode a `soft_fail` transaction
# TODO: provoke an `expired` transaction. How to do that? Too loaded and can't push it through?
# TODO: fail a deferred that wrote things to storage... we need to make sure this does NOT go
#       into fluxdb, yet the RAM for `deferred_trx_removed` should be applied.. hmm...

echo "Exiting in 1 sec"
sleep 1
