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

  deep_mind_log_file="./deep-mind.dmlog"
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

  eosc tx create battlefield1 dtrx '{"account": "battlefield1", "fail_now": false, "fail_later": false, "fail_later_nested": false, "delay_sec": 1, "nonce": "1"}' -p battlefield1
  eosc tx create battlefield1 dtrxcancel '{"account": "battlefield1"}' -p battlefield1
  sleep 0.6

  eosc tx create battlefield1 dtrx '{"account": "battlefield1", "fail_now": true, "fail_later": false, "fail_later_nested": false, "delay_sec": 1, "nonce": "1"}' -p battlefield1 || true
  sleep 0.6
  echo "The error message you see above ^^^ is OK, we were expecting the transaction to fail, continuing...."

  # `send_deferred` with `replace_existing` enabled, to test `MODIFY` clauses.
  eosc tx create battlefield1 dtrx '{"account": "battlefield1", "fail_now": false, "fail_later": false, "fail_later_nested": false, "delay_sec": 1, "nonce": "1"}' -p battlefield1
  eosc tx create battlefield1 dtrx '{"account": "battlefield1", "fail_now": false, "fail_later": false, "fail_later_nested": false, "delay_sec": 1, "nonce": "2"}' -p battlefield1
  sleep 0.6

  eosc tx create battlefield1 dtrx '{"account": "battlefield1", "fail_now": false, "fail_later": true, "fail_later_nested": false, "delay_sec": 1, "nonce": "1"}' -p battlefield1
  echo ""
  echo "Waiting for the transaction to fail (no onerror handler)..."
  sleep 1.1

  eosc tx create battlefield1 dtrx '{"account": "battlefield1", "fail_now": false, "fail_later": false, "fail_later_nested": true, "delay_sec": 1, "nonce": "2"}' -p battlefield1
  echo ""
  echo "Waiting for the transaction to fail (no onerror handler)..."
  sleep 1.1

  eosc tx create battlefield3 dtrx '{"account": "battlefield3", "fail_now": false, "fail_later": true, "fail_later_nested": false, "delay_sec": 1, "nonce": "1"}' -p battlefield3
  echo ""
  echo "Waiting for the transaction to fail (with onerror handler that succeed)..."
  sleep 1.1

  eosc tx create battlefield3 dtrx '{"account": "battlefield3", "fail_now": false, "fail_later": true, "fail_later_nested": false, "delay_sec": 1, "nonce": "f"}' -p battlefield3
  echo ""
  echo "Waiting for the transaction to fail (with onerror handler that failed)..."
  sleep 1.1

  eosc tx create battlefield1 dbinstwo '{"account": "battlefield1", "first": 100, "second": 101}' -p battlefield1
  # This TX will do one DB_OPERATION for writing, and the second will fail. We want our instrumentation NOT to keep that DB_OPERATION.
  eosc tx create --delay-sec=1 battlefield1 dbinstwo '{"account": "battlefield1", "first": 102, "second": 100}' -p battlefield1
  echo ""
  echo "Waiting for the transaction to fail, yet attempt to write to storage"
  sleep 1.1

  # This TX will show a delay transaction (deferred) that succeeds
  eosc tx create --delay-sec=1 eosio.token transfer '{"from": "eosio", "to": "battlefield1", "quantity": "1.0000 EOS", "memo":"push delayed trx"}' -p eosio
  echo ""
  echo "Waiting for the transaction to fail, yet attempt to write to storage"
  sleep 1.1

  # This is to see how the RAM_USAGE behaves, when a deferred hard_fails. Does it refund the deferred_trx_remove ? What about the other RAM tweaks? Any one them saved?
  eosc tx create battlefield1 dbinstwo '{"account": "battlefield1", "first": 200, "second": 201}' -p battlefield1
  sleep 0.6

  echo ""
  echo -n "Create a delayed and cancel it (in same block) with 'eosio:canceldelay'"
  eosc tx create --delay-sec=3600 battlefield1 dbins '{"account": "battlefield1"}' -p battlefield1 --write-transaction /tmp/delayed.json
  ID=`eosc tx id /tmp/delayed.json`
  eosc tx push /tmp/delayed.json
  eosc tx cancel battlefield1 $ID
  rm /tmp/delayed.json || true

  sleep 0.6

  echo ""
  echo -n "Create a delayed and cancel it (in different block) with 'eosio:canceldelay'"
  eosc tx create --delay-sec=3600 battlefield1 dbins '{"account": "battlefield1"}' -p battlefield1 --write-transaction /tmp/delayed.json
  ID=`eosc tx id /tmp/delayed.json`
  eosc tx push /tmp/delayed.json
  sleep 1.1

  eosc tx cancel battlefield1 $ID
  rm /tmp/delayed.json || true
  sleep 0.6

  echo ""
  echo -n "Create auth structs, updateauth to create, updateauth to modify, deleteauth to test AUTH_OPs"
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
  echo -n "Create a creational order different than the execution order"
  ## We use the --force-unique flag so a context-free action exist in the transactions traces tree prior our own,
  ## creating a multi-root execution traces tree.
  eosc tx create --force-unique battlefield1 creaorder '{"n1": "notified1", "n2": "notified2", "n3": "notified3", "n4": "notified4", "n5": "notified5"}' -p battlefield1
  sleep 0.6

  #
  ## Producer Schedule Change
  #

  echo ""
  echo -n "Using eosio.bios contract temporarly to set producers"
  eosc system setcontract eosio contracts/eosio.bios-1.5.2.wasm contracts/eosio.bios-1.5.2.abi
  sleep 0.6

  echo ""
  echo -n "Updating producers"
  eosc tx create eosio setprods '{"schedule": [{"producer_name": "eosio2", "block_signing_key":"EOS5MHPYyhjBjnQZejzZHqHewPWhGTfQWSVTWYEhDmJu4SXkzgweP"}]}' -p eosio@active
  sleep 1.8

  echo ""
  echo -n "Returning eosio contract to standard eosio.system contract"
  eosc system setcontract eosio contracts/eosio.system-1.5.2.wasm contracts/eosio.system-1.5.2.abi
  sleep 0.6

  #
  ## Protocol Features
  #

  known_features=`curl -s "$EOSC_GLOBAL_API_URL/v1/producer/get_supported_protocol_features" | jq -cr '.[]'`

  echo ""
  echo "Available protocol features"
  echo $known_features | jq -r '. | "- \(.specification[].value) (Digest \(.feature_digest))"'

  echo ""
  echo "Activating protocol features"
  curl -s -X POST "$EOSC_GLOBAL_API_URL/v1/producer/schedule_protocol_feature_activations" -d '{"protocol_features_to_activate": ["0ec7e080177b2c02b278d5088611686b49d739925a92d9bfcacd7fc6b74053bd"]}' > /dev/null
  eosc system setcontract eosio contracts/eosio.system-1.7.0-rc1.wasm contracts/eosio.system-1.7.0-rc1.abi
  sleep 1.8

  # This activates all known protocol features (RAM correction operations, WebAuthN keys, WTMSIG blocks, etc)
  echo ""
  echo "Activating all protocol features"
  for feature in `echo $known_features | jq -c . | grep -v "0ec7e080177b2c02b278d5088611686b49d739925a92d9bfcacd7fc6b74053bd"`; do
    digest=`echo "$feature" | jq -cr .feature_digest`
    eosc tx create eosio activate "{\"feature_digest\":\"$digest\"}" -p eosio@active
  done

  # Activating all protocol features requires around 6 blocks to complete, so let's give 7 for a small buffer
  sleep 3.6

  #
  ## WebAuthN keys
  #

  ## WebAuthN Generation
  #
  # The WebAuthN key generation involves a Browser. We have a quick Node.js server that
  # perform the general logic of getting a WebAuthN public/private key pair and signed and
  # hard-coded transaction for us.
  #
  # This requires first to have call the `yarn generate` key to generate a key (you will
  # need your YubiKey also to generate the key material).
  #
  # Once you have your publick key (it gets copied to the clipboard on the generation),
  # the following snippets will work.
  WEBAUTHN_PUBLIC_KEY="PUB_WA_7qjMn38M4Q6s8wamMcakZSXLm4vDpHcLqcehnWKb8TJJUMzpEZNw41pTLk6Uhqp7p"

  eosc system newaccount eosio battlefield4 --auth-key $WEBAUTHN_PUBLIC_KEY --stake-cpu 1 --stake-net 1 --transfer
  eosc transfer eosio battlefield4 "200.0000 EOS"
  sleep 0.6

  ## WebAuthN Signing
  #
  # Based on your previously generated public key, this will open a Browser, ask
  # and ask him to sign a transaction and send it to our local node, effectively
  # creating a transaction signed with a WebAuthN key
  #
  echo ""
  echo "About to push a WebAuthN signed transaction"
  cd webauthn_signer
  yarn -s run transfer || true
  sleep 0.6
  cd ..

  #
  ## WTMSIG blocks (EOSIO 2.0 protocol feature WTMSIG_BLOCK_SIGNATURES)
  #

  ## Producer Schedule
  #
  # A change to producer schedule was reported as a `NewProducers` field on the
  # the `BlockHeader` in EOSIO 1.x. In EOSIO 2.x, when feature `WTMSIG_BLOCK_SIGNATURES`
  # is activated, the `NewProducers` field is not present anymore and the schedule change
  # is reported through a `BlockHeaderExtension` on the the `BlockHeader` struct.
  #
  # Here, we simulate such change
  echo ""
  echo "About to test WTMSIG_BLOCK_SIGNATURES protocol feature"
  echo -n "Using eosio.bios contract temporarly to set producers"
  eosc system setcontract eosio contracts/eosio.bios-1.5.2.wasm contracts/eosio.bios-1.5.2.abi
  sleep 0.6

  echo ""
  echo -n "Updating producers"
  eosc tx create eosio setprods '{"schedule": [{"producer_name": "eosio3", "block_signing_key":"EOS5MHPYyhjBjnQZejzZHqHewPWhGTfQWSVTWYEhDmJu4SXkzgweP"}]}' -p eosio@active
  sleep 1.8

  echo ""
  echo -n "Returning eosio contract to standard eosio.system contract"
  eosc system setcontract eosio contracts/eosio.system-1.7.0-rc1.wasm contracts/eosio.system-1.7.0-rc1.abi
  sleep 0.6

  # Not required yet, but often leads to transaction max execution time reached, so will need some tweaks to config I guess...
  # echo ""
  # echo "Updating to latest system contracts"
  # eosc system setcontract eosio contracts/eosio.system-1.9.0.wasm contracts/eosio.system-1.9.0.abi
  # sleep 0.6

  # TODO: provoke a `soft_fail` transaction
  # TODO: provoke an `expired` transaction. How to do that? Too loaded and can't push it through?

  # Kill `nodeos` process
  echo ""
  echo "Exiting in 1 sec"
  sleep 1

  if [[ $nodeos_pid != "" ]]; then
    kill -s TERM $nodeos_pid &> /dev/null || true
    sleep 0.5
  fi

  # Print Deep Mind Statistics
  set +ex
  echo "Statistics"
  echo " Blocks: `cat "$deep_mind_log_file" | grep "ACCEPTED_BLOCK" | wc -l | tr -d ' '`"
  echo " Transactions: `cat "$deep_mind_log_file" | grep "APPLIED_TRANSACTION" | wc -l | tr -d ' '`"
  echo ""
  echo " Creation Op: `cat "$deep_mind_log_file" | grep "CREATION_OP" | wc -l | tr -d ' '`"
  echo " Database Op: `cat "$deep_mind_log_file" | grep "DB_OP" | wc -l | tr -d ' '`"
  echo " Deferred Transaction Op: `cat "$deep_mind_log_file" | grep "DTRX_OP" | wc -l | tr -d ' '`"
  echo " Feature Op: `cat "$deep_mind_log_file" | grep "FEATURE_OP" | wc -l | tr -d ' '`"
  echo " Permission Op: `cat "$deep_mind_log_file" | grep "PERM_OP" | wc -l | tr -d ' '`"
  echo " Resource Limits Op: `cat "$deep_mind_log_file" | grep "RLIMIT_OP" | wc -l | tr -d ' '`"
  echo " RAM Op: `cat "$deep_mind_log_file" | grep "RAM_OP" | wc -l | tr -d ' '`"
  echo " RAM Correction Op: `cat "$deep_mind_log_file" | grep "RAM_CORRECTION_OP" | wc -l | tr -d ' '`"
  echo " Table Op: `cat "$deep_mind_log_file" | grep "TBL_OP" | wc -l | tr -d ' '`"
  echo " Transaction Op: `cat "$deep_mind_log_file" | grep "TRX_OP" | wc -l | tr -d ' '`"
  echo ""

  echo "Inspect log files"
  echo " Deep Mind logs: cat $deep_mind_log_file"
  echo " Nodeos logs: cat $nodeos_log_file"
  echo " eosc boot logs: cat $eosc_boot_log_file"
  echo ""
}

main $@
