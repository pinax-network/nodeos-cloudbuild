#!/bin/bash -e

if [ "$1" == "" ]; then
    echo "Specify the path to nodeos, or a nodeos Docker image"
    exit 1
fi

rm -rf blocks/ state/
cp -arv ../boot/blocks/ .

if [ -f $1 ]; then
    # Execute a local instance
    $1 --data-dir=`pwd` --config-dir=`pwd` --replay-blockchain > output.log &
    PID=$!

    sleep 6

    kill $PID
else
    # Assume it's a Docker image name
    CONTAINER_NAME=deep-mind-compare
    docker kill deep-mind-compare || true
    docker run --name deep-mind-compare --rm -v `pwd`:/data -w /data $1 /bin/bash -c "/opt/eosio/bin/nodeos --data-dir=/data --config-dir=/data --replay-blockchain > output.log" &

    sleep 6

    docker kill deep-mind-compare
fi

sed -i 's/,"elapsed":[0-9]*,"/,"elapsed":0,"/g' output.log
sed -i 's/"thread_name":"thread-[0-9]*","timestamp":"[^"]*"}/"thread_name":"thread-0","timestamp":"9999-99-99T99:99:99.999"}/g' output.log

diff -u reference.log output.log | tee diff.log

if [ "$(cat diff.log | wc -l)" != "0" ]; then
    echo Some differences found between deep-mind reference log and logs produced by this build
    exit 1
else
    echo No differences found with this version of the deep-mind instrumentation and the reference log.
fi
