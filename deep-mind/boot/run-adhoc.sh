#!/bin/bash

set -e

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

EOS_BIN="$1"
LOG_FILE=${LOG_FILE:-"$ROOT/deep-mind-adhoc.log"}
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

echo -n "Setting eosio.code permissions on contract accounts (Account for commit d8fa7c0, which shields from mis-used authority)"
eosc system updateauth battlefield1 active owner "$ROOT"/active_auth_battlefield1.yaml
eosc system updateauth battlefield3 active owner "$ROOT"/active_auth_battlefield3.yaml
eosc system updateauth notified2 active owner "$ROOT"/active_auth_notified2.yaml
sleep 0.6

eosc tx create battlefield1 dbins '{"account": "battlefield1"}' -p battlefield1
sleep 0.6

echo ""
echo "Exiting in 1 sec"
sleep 1

kill -s TERM $PID
sleep 0.5

# Print Log Locations

set +ex
echo ""
echo "# Logs"
echo ""
echo "- Deep mind: ${LOG_FILE}"
echo "- Nodeos: ${NODEOS_FILE}"
echo "- EOS BIOS: ${BIOS_BOOT_FILE}"
echo ""

