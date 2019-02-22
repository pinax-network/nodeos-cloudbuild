#!/bin/bash

set -e

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

EOS_BIN="$1"
LOG_FILE=${LOG_FILE:-"$ROOT/deep-mind-adhoc.log"}
NODEOS_FILE=${NODEOS_FILE:-"$ROOT/nodeos.log"}

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
mv output.log bios-boot.log
popd

echo "Booting completed, launching test cases..."

export EOSC_GLOBAL_INSECURE_VAULT_PASSPHRASE=secure
export EOSC_GLOBAL_API_URL=http://localhost:9898
export EOSC_GLOBAL_VAULT_FILE="$ROOT/eosc-vault.json"

# Account for commit d8fa7c07ee48e26a1b8e0cf7f098a6a02532922e, which shields from mis-used authority.
eosc system updateauth notified2 active owner notified2_active_auth.yaml

eosc tx create battlefield1 creaorder '{"n1": "notified1", "n2": "notified2", "n3": "notified3", "n4": "notified4", "n5": "notified5"}' -p battlefield1
sleep 0.6

echo ""
echo "Exiting in 1 sec"
sleep 1

kill -s TERM $PID
sleep 0.5

# Print Log

set +ex
echo ""
cat $LOG_FILE
