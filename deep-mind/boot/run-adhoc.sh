#!/bin/bash

set -e

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

nodeos_pid=""
current_dir=`pwd`

function cleanup {
    if [[ $nodeos_pid != "" ]]; then
      echo "Closing nodeos process"
      kill -s TERM $nodeos_pid &> /dev/null || true
    fi

    cd $current_dir
    exit 0
}

function main() {
  eos_bin="$1"

  if [[ ! -f $eos_bin ]]; then
    echo "The 'nodeos' binary received does not exist, check first provided argument."
    exit 1
  fi

  # Trap exit signal and clean up
  trap cleanup EXIT

  pushd $ROOT &> /dev/null

  deep_mind_log_file="./deep-mind-adhoc.dmlog"
  nodeos_log_file="./nodeos.log"
  eosc_boot_log_file="./eosc-boot.log"

  rm -rf "$ROOT/blocks/" "$ROOT/state/"

  ($eos_bin --data-dir="$ROOT" --config-dir="$ROOT" --genesis-json="$ROOT/genesis.json" 1> $deep_mind_log_file 2> $nodeos_log_file) &
  nodeos_pid=$!

  echo "Booting $1 node with smart contracts ..."
  eosc boot bootseq.yaml --reuse-genesis --api-url http://localhost:9898 1> /dev/null
  mv output.log ${eosc_boot_log_file}
  popd 1> /dev/null

  echo "Booting completed, launching test cases..."

  export EOSC_GLOBAL_INSECURE_VAULT_PASSPHRASE=secure
  export EOSC_GLOBAL_API_URL=http://localhost:9898
  export EOSC_GLOBAL_VAULT_FILE="$ROOT/eosc-vault.json"

  echo "Setting eosio.code permissions on contract accounts (Account for commit d8fa7c0, which shields from mis-used authority)"
  eosc system updateauth battlefield1 active owner "$ROOT"/active_auth_battlefield1.yaml
  eosc system updateauth battlefield3 active owner "$ROOT"/active_auth_battlefield3.yaml
  eosc system updateauth notified2 active owner "$ROOT"/active_auth_notified2.yaml
  sleep 0.6

  # Add your ad hoc transactions here

  echo ""
  echo "Exiting in 1 sec"
  sleep 1

  if [[ $nodeos_pid != "" ]]; then
    kill -s TERM $nodeos_pid &> /dev/null || true
    sleep 0.5
  fi

  # Print Log Files
  echo "Inspect log files"
  echo " Deep Mind logs: cat $deep_mind_log_file"
  echo " Nodeos logs: cat $nodeos_log_file"
  echo " eosc boot logs: cat $eosc_boot_log_file"
  echo ""
}

main $@
