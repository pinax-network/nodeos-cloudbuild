#!/bin/bash

set -e

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

EOS_BIN="$1"
LOG_FILE=${LOG_FILE:-"$ROOT/deep-mind.log"}
NODEOS_FILE=${NODEOS_FILE:-"$ROOT/nodeos.log"}
BIOS_BOOT_FILE=${BIOS_BOOT_FILE:-"$ROOT/bios-boot.log"}

if [[ ! -f $EOS_BIN ]]; then
    echo "The 'nodeos' binary received does not exist, check first provided argument."
    exit 1
fi

rm -rf "$ROOT/blocks/" "$ROOT/state/"

($EOS_BIN --data-dir="$ROOT" --config-dir="$ROOT" --genesis-json="$ROOT/genesis.json" 1> $LOG_FILE 2> $NODEOS_FILE) &
PID=$!

# Trap exit signal and closes all `nodeos` instances when exiting
trap "kill -s TERM $PID || true" EXIT

pushd $ROOT &> /dev/null
echo "Booting $1 node with smart contracts ..."
eos-bios boot bootseq.yaml --reuse-genesis --api-url http://localhost:9898
mv output.log ${BIOS_BOOT_FILE}
popd

echo "Booting completed, launching test cases..."

export EOSC_GLOBAL_INSECURE_VAULT_PASSPHRASE=secure
export EOSC_GLOBAL_API_URL=http://localhost:9898
export EOSC_GLOBAL_VAULT_FILE="$ROOT/eosc-vault.json"

# Account for commit d8fa7c07ee48e26a1b8e0cf7f098a6a02532922e, which shields from mis-used authority.
eosc system updateauth battlefield1 active owner battlefield_active_auth.yaml
sleep 0.6

eosc system updateauth notified2 active owner notified2_active_auth.yaml
sleep 0.6

eosc transfer eosio battlefield1 100000 --memo "go habs go"
sleep 0.6

eosc system newaccount battlefield1 battlefield2 --auth-key EOS5MHPYyhjBjnQZejzZHqHewPWhGTfQWSVTWYEhDmJu4SXkzgweP --stake-cpu 1 --stake-net 1 --transfer
sleep 0.6

eosc tx create battlefield1 dbins '{"account": "battlefield1"}' -p battlefield1
sleep 0.6

eosc tx create battlefield1 dbupd '{"account": "battlefield2"}' -p battlefield2
sleep 0.6

eosc tx create battlefield1 dbrem '{"account": "battlefield1"}' -p battlefield1
sleep 0.6

eosc tx create battlefield1 dtrx '{"account": "battlefield1", "fail_now": false, "fail_later": false, "delay_sec": 1, "nonce": "1"}' -p battlefield1
eosc tx create battlefield1 dtrxcancel '{"account": "battlefield1"}' -p battlefield1
sleep 0.6

eosc tx create battlefield1 dtrx '{"account": "battlefield1", "fail_now": true, "fail_later": false, "delay_sec": 1, "nonce": "1"}' -p battlefield1 || true
sleep 0.6
echo "The error message you see above ^^^ is OK, we were expecting the transaction to fail, continuing...."

# `send_deferred` with `replace_existing` enabled, to test `MODIFY` clauses.
eosc tx create battlefield1 dtrx '{"account": "battlefield1", "fail_now": false, "fail_later": false, "delay_sec": 1, "nonce": "1"}' -p battlefield1
eosc tx create battlefield1 dtrx '{"account": "battlefield1", "fail_now": false, "fail_later": false, "delay_sec": 1, "nonce": "2"}' -p battlefield1
sleep 0.6

eosc tx create battlefield1 dtrx '{"account": "battlefield1", "fail_now": false, "fail_later": true, "delay_sec": 1, "nonce": "1"}' -p battlefield1

echo ""
echo "Waiting for the transaction to fail..."
sleep 1.1

eosc tx create battlefield1 dbinstwo '{"account": "battlefield1", "first": 100, "second": 101}' -p battlefield1
# This TX will do one DB_OPERATION for writing, and the second will fail. We want our instrumentation NOT to keep that DB_OPERATION.
eosc tx create --delay-sec=1 battlefield1 dbinstwo '{"account": "battlefield1", "first": 102, "second": 100}' -p battlefield1

echo ""
echo "Waiting for the transaction to fail, yet attempt to write to storage"
sleep 1.1

# This is to see how the RAM_USAGE behaves, when a deferred hard_fails. Does it refund the deferred_trx_remove ? What about the other RAM tweaks? Any one them saved?
eosc tx create battlefield1 dbinstwo '{"account": "battlefield1", "first": 200, "second": 201}' -p battlefield1
sleep 0.6

echo ""
echo "Create a delayed and cancel it with 'eosio:canceldelay'"
eosc tx create --delay-sec=3600 battlefield1 dbins '{"account": "battlefield1"}' -p battlefield1 --write-transaction /tmp/delayed.json
ID=`eosc tx id /tmp/delayed.json`
eosc tx push /tmp/delayed.json
eosc tx cancel battlefield1 $ID
rm /tmp/delayed.json || true

sleep 0.6

echo ""
echo "Create auth structs, updateauth to create, updateauth to modify, deleteauth to test AUTH_OPs"
eosc system updateauth battlefield2 ops active EOS7f5watu1cLgth3ub1uAnsGkHq1F6PhauScBg6rJGUfe79MgG9Y # random key
sleep 0.6

eosc system updateauth battlefield2 ops active EOS5MHPYyhjBjnQZejzZHqHewPWhGTfQWSVTWYEhDmJu4SXkzgweP # back to safe key
sleep 0.6

eosc system linkauth battlefield2 eosio.token transfer ops
sleep 0.6

eosc system unlinkauth battlefield2 eosio.token transfer
sleep 0.6

eosc system deleteauth battlefield2 ops
sleep 0.6

echo ""
echo "Create a creational order different than the execution order"
eosc tx create --force-unique battlefield1 creaorder '{"n1": "notified1", "n2": "notified2", "n3": "notified3", "n4": "notified4", "n5": "notified5"}' -p battlefield1
sleep 0.6

# TODO: provode a `soft_fail` transaction
# TODO: provoke an `expired` transaction. How to do that? Too loaded and can't push it through?
# TODO: fail a deferred that wrote things to storage... we need to make sure this does NOT go
#       into fluxdb, yet the RAM for `deferred_trx_removed` should be applied.. hmm...

# Kill `nodeos` process

echo ""
echo "Exiting in 3 sec"
sleep 3

kill -s TERM $PID
sleep 0.5

# Print Deep Mind Statistics

set +ex
echo ""
echo "# Statistics"
printf "## Deferred (DTRX_OP): "
cat $LOG_FILE | grep -E "DTRX_OP" | wc -l
echo ""

cat $LOG_FILE | grep -E "DTRX_OP" | cut -f 1,2,3,4,5,6,7,8 -d ' '
echo ""

printf "## Database (DB_OP): "
cat $LOG_FILE | grep "DB_OP" | wc -l
echo ""

cat $LOG_FILE | grep "DB_OP" | cut -f 1,2,3,4,5,6,7,8,9 -d ' '
echo ""

printf "## Execution (EXEC_OP): "
cat $LOG_FILE | grep "EXEC_OP" | wc -l
echo ""

cat $LOG_FILE | grep "EXEC_OP" | cut -f 1,2,3,4 -d ' '
echo ""

printf "## Permission (PERM_OP): "
cat $LOG_FILE | grep "PERM_OP" | wc -l
echo ""

cat $LOG_FILE | grep "PERM_OP" | cut -f 1,2,3,4 -d ' '
echo ""

printf "## Resource Limits (RLIMIT_OP): "
cat $LOG_FILE | grep "RLIMIT_OP" | wc -l
echo ""

cat $LOG_FILE | grep -E "RLIMIT_OP (CONFIG|STATE)" | cut -f 1,2,3,4 -d ' '
cat $LOG_FILE | grep "RLIMIT_OP ACCOUNT_" | cut -f 1,2,3,4,5 -d ' '
echo ""

printf "## RAM (RAM_OP): "
cat $LOG_FILE | grep "RAM_OP" | wc -l
echo ""

cat $LOG_FILE | grep "RAM_OP" | cut -f 1,2,3,4,5,6,7,8 -d ' '
echo ""

printf "## Table (TBL_OP): "
cat $LOG_FILE | grep "TBL_OP" | wc -l
echo ""

cat $LOG_FILE | grep "TBL_OP" | cut -f 1,2,3,4,5,6,7,8 -d ' '
echo ""

# Print Log Locations

echo "# Logs"
echo ""
echo "- Deep mind: ${LOG_FILE}"
echo "- Nodeos: ${NODEOS_FILE}"
echo "- EOS BIOS: ${BIOS_BOOT_FILE}"
echo ""
