#!/bin/bash

set -e

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURRENT=`pwd`

EOS_BIN_OR_DOCKER="$1"
LOG_FILE=${LOG_FILE:-"/tmp/battlefield.log"}

if [ "$EOS_BIN_OR_DOCKER" == "" ]; then
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

rm -rf "$ROOT/blocks/" "$ROOT/protocol_features/" "$ROOT/state/"
cp -av "$ROOT/../boot/blocks" "$ROOT/"
rm -rf "$ROOT/blocks/reversible"
cp -av "$ROOT/../boot/protocol_features" "$ROOT/"

if [ -f $EOS_BIN_OR_DOCKER ]; then
    # Execute a local instance
    $EOS_BIN_OR_DOCKER --data-dir=$ROOT --config-dir=$ROOT --replay-blockchain > "$ROOT/output.log" &
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
        -v $ROOT:/app \
        $EOS_BIN_OR_DOCKER \
        /bin/bash -c "/opt/eosio/bin/nodeos --data-dir=/app --config-dir=/app --replay-blockchain > /app/output.log" &

    # Trap exit signal and close docker image
    trap "finish" EXIT

    echo "Giving 20s for docker process to fully complete replay"
    sleep 20
    docker kill $CONTAINER_NAME || true
fi

OUTPUT_FILE_PATTERN="$ROOT/output"
REFERENCE_FILE_PATTERN="$ROOT/reference"

OUTPUT_FILE="$OUTPUT_FILE_PATTERN.log"
REFERENCE_FILE="$REFERENCE_FILE_PATTERN.log"
DIFF_FILE="$ROOT/diff.patch"

sed -i.bak -e 's/,"elapsed":[0-9]*,"/,"elapsed":0,"/g' "$OUTPUT_FILE"
sed -i.bak -e 's/"thread_name":"thread-[0-9]*","timestamp":"[^"]*"}/"thread_name":"thread-0","timestamp":"9999-99-99T99:99:99.999"}/g' "$OUTPUT_FILE"
sed -i.bak -e 's/,"line":[0-9]*,"/,"line":0,"/g' "$OUTPUT_FILE"
sed -i.bak -e 's/\([,{]\)"last_ordinal":[0-9]*,"/\1"last_ordinal":0,"/g' "$OUTPUT_FILE"
sed -i.bak -e 's/\([,{]\)"last_updated":"[^"]*","/\1"last_updated":"9999-99-99T99:99:99.999","/g' "$OUTPUT_FILE"
rm -rf "$OUTPUT_FILE.bak"

set +e

diff -u "$REFERENCE_FILE" "$OUTPUT_FILE" > "$DIFF_FILE"

echo "Checking for difference between reference and output files ..."
difference_found=""
if [ "$(cat $DIFF_FILE | wc -l | tr -d ' ')" != "0" ]; then
    echo "Some differences found between deep-mind reference log and logs produced by this build"
    printf "Check them right now? (y/N) "
    if [[ $CI == "" ]]; then
        read value

        if [[ $value == "y" || $value == "yes", || $value == "Y" ]]; then
            less $DIFF_FILE
        fi
    else
        less $DIFF_FILE
    fi

    echo ""
    echo "You can check differences later on this file:"
    echo "$DIFF_FILE"

    difference_found="true"
else
    echo "No differences found with this version of the deep-mind instrumentation and the reference log."
fi

if [[ "$SKIP_GO_TESTS" == "" ]]; then
    echo ""
    echo "Running unit tests..."

    current=`pwd`
    trap "cd $current" EXIT

    cd "$ROOT"
    go test ./...
    if [[ $? != 0 ]]; then
        difference_found="true"
    fi
else
    echo "The go tests are disabled (SKIP_GO_TESTS=true)"
fi

if [[ "$difference_found" == "true" ]]; then
    echo ""
    echo "You can accept the changes by doing the following command:"
    echo "cp $OUTPUT_FILE $REFERENCE_FILE"
    echo "cp $OUTPUT_FILE_PATTERN.jsonl $REFERENCE_FILE_PATTERN.jsonl"
    echo "cp $OUTPUT_FILE_PATTERN.stats.json $REFERENCE_FILE_PATTERN.stats.json"

    exit 1
else
    echo "Everything is right, success."
fi
