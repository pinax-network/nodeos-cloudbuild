#!/bin/bash

set -e

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURRENT=`pwd`

target="$1"
eos_bin_or_docker="$2"

if [[ ! -d "$ROOT/$target" ]]; then
    echo "The target dirctory '$ROOT/$target' does not exist, check first provided argument."
    exit 1
fi

if [[ "$eos_bin_or_docker" == "" ]]; then
    echo "Specify the path to nodeos, or a nodeos Docker image"
    exit 1
fi

function finish {
    set +e
    echo "Cleaning up"
    [[ $PID != "" ]] && (kill -s TERM $PID || true)
    [[ $CONTAINER_NAME != "" ]] && (docker kill $CONTAINER_NAME || true)

    cd $current

    exit 0
}

rm -rf "$ROOT/$target/blocks/" "$ROOT/$target/protocol_features/" "$ROOT/$target/state/"
cp -av "$ROOT/../boot/$target/blocks" "$ROOT/$target/"
rm -rf "$ROOT/$target/blocks/reversible"
cp -av "$ROOT/../boot/$target/protocol_features" "$ROOT/$target/"

if [ -f $eos_bin_or_docker ]; then
    # Execute a local instance
    $eos_bin_or_docker --data-dir=$ROOT/$target --config-dir=$ROOT/$target --replay-blockchain > "$ROOT/$target/actual.dmlog" &
    PID=$!

    # Trap exit signal and close nodeos process
    trap "finish" EXIT

    echo "Giving 20s for nodeos process to fully complete replay"
    sleep 20
    kill $PID || true
else
    # Assume it's a Docker image name
    CONTAINER_NAME=deep-mind-compare
    docker kill $CONTAINER_NAME 2> /dev/null || true
    docker run \
        --rm \
        --name $CONTAINER_NAME \
        -v $ROOT/$target:/app \
        $eos_bin_or_docker \
        /bin/bash -c "/opt/eosio/bin/nodeos --data-dir=/app --config-dir=/app --replay-blockchain > /app/actual.dmlog" &

    # Trap exit signal and close docker image
    trap "finish" EXIT

    echo "Giving 20s for docker process to fully complete replay"
    sleep 20
    docker kill $CONTAINER_NAME || true
fi

echo ""
echo "Performing sanity check to ensure new versions is identical to new version ..."

current=`pwd`
trap "cd $current" EXIT

cd "$ROOT"
TARGET="$target" go test ./...

# ACTUAL_FILE_PATTERN="$ROOT/$target/actual"
# REFERENCE_FILE_PATTERN="$ROOT/$target/expected"

# ACTUAL_FILE="$ACTUAL_FILE_PATTERN.log"
# REFERENCE_FILE="$REFERENCE_FILE_PATTERN.log"
# DIFF_FILE="$ROOT/diff.patch"

# sed -i.bak -e 's/,"elapsed":[0-9]*,"/,"elapsed":0,"/g' "$ACTUAL_FILE"
# sed -i.bak -e 's/"thread_name":"[^"]*","timestamp":"[^"]*"}/"thread_name":"thread-0","timestamp":"3333-12-31T00:01:02.345"}/g' "$ACTUAL_FILE"
# sed -i.bak -e 's/,"line":[0-9]*,"/,"line":0,"/g' "$ACTUAL_FILE"
# sed -i.bak -e 's/\([,{]\)"last_ordinal":[0-9]*,"/\1"last_ordinal":0,"/g' "$ACTUAL_FILE"
# sed -i.bak -e 's/\([,{]\)"last_updated":"[^"]*","/\1"last_updated":"3333-12-31T00:01:02.345","/g' "$ACTUAL_FILE"

# # Only needed in `develop` branch of `nodeos` for now, since it's now different since generated set didn't had `return_value`
# sed -i.bak -e 's/,"return_value":""//g' "$ACTUAL_FILE"

# rm -rf "$ACTUAL_FILE.bak"

# set +e

# diff -u "$REFERENCE_FILE" "$ACTUAL_FILE" > "$DIFF_FILE"

# echo "Checking for difference between reference and output files ..."
# difference_found=""
# if [ "$(cat $DIFF_FILE | wc -l | tr -d ' ')" != "0" ]; then
#     echo "Some differences found between deep-mind reference log and logs produced by this build"
#     printf "Check them right now? (y/N) "
#     if [[ $CI == "" ]]; then
#         read value

#         if [[ $value == "y" || $value == "yes", || $value == "Y" ]]; then
#             less $DIFF_FILE
#         fi
#     else
#         less $DIFF_FILE
#     fi

#     echo ""
#     echo "You can check differences later on this file:"
#     echo "$DIFF_FILE"

#     difference_found="true"
# else
#     echo "No differences found with this version of the deep-mind instrumentation and the reference log."
# fi

# if [[ "$SKIP_GO_TESTS" == "" ]]; then
#     echo ""
#     echo "Running unit tests..."

#     current=`pwd`
#     trap "cd $current" EXIT

#     cd "$ROOT"
#     TARGET="$target" go test ./...
#     if [[ $? != 0 ]]; then
#         difference_found="true"
#     fi
# else
#     echo "The go tests are disabled (SKIP_GO_TESTS=true)"
# fi

# if [[ "$difference_found" == "true" ]]; then
#     echo ""
#     echo "You can accept the changes by doing the following command:"
#     echo "cp $ACTUAL_FILE $REFERENCE_FILE"
#     echo "cp $ACTUAL_FILE_PATTERN.jsonl $REFERENCE_FILE_PATTERN.jsonl"
#     echo "cp $ACTUAL_FILE_PATTERN.stats.json $REFERENCE_FILE_PATTERN.stats.json"

#     exit 1
# else
#     echo "Everything is right, success."
# fi
