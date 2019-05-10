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

# Account for commit d8fa7c07ee48e26a1b8e0cf7f098a6a02532922e, which shields from mis-used authority.
eosc system updateauth notified2 active owner notified2_active_auth.yaml

echo ""
echo "Create a creational order different than the execution order"
eosc tx create --force-unique battlefield1 creaorder '{"n1": "notified1", "n2": "notified2", "n3": "notified3", "n4": "notified4", "n5": "notified5"}' -p battlefield1
sleep 0.6

echo ""
echo "Activating protocol features"
curl -X POST "$EOSC_GLOBAL_API_URL/v1/producer/schedule_protocol_feature_activations" -d '{"protocol_features_to_activate": ["0ec7e080177b2c02b278d5088611686b49d739925a92d9bfcacd7fc6b74053bd"]}' > /dev/null
sleep 1.2

eosc system setcontract eosio contracts/eosio.system.wasm contracts/eosio.system.abi
sleep 0.6

echo "Activate protocol feature (REPLACE_DEFERRED)"
eosc tx create eosio activate '{"feature_digest":"ef43112c6543b88db2283a2e077278c315ae2c84719a8b25f25cc88565fbea99"}' -p eosio@activesleep 1.2
sleep 1.2

echo "Activate protocol feature (NO_DUPLICATE_DEFERRED_ID)"
eosc tx create eosio activate '{"feature_digest":"4a90c00d55454dc5b059055ca213579c6ea856967712a56017487886a4d4cc0f"}' -p eosio@activesleep 1.2
sleep 1.2

echo ""
echo "Exiting in 1 sec"
sleep 1000

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

