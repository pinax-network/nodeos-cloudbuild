#!/usr/bin/env bash

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function main() {
    cd $ROOT

    if [[ ! -f "genesis.json" ]]; then
        echo "File genesis.json must exist, something fishy here"
        exit 1
    fi

    if [[ ! -f "blocks/blocks.log" ]]; then
        echo "File blocks/blocks.log must exist, have you executed 'run.sh' script?"
        exit 1
    fi

    echo "Uploading 'genesis.json' and 'blocks/blocks.log' file to 'gs://dfuseio-global-seed-us/eos-dev1/'"
    gsutil cp genesis.json gs://dfuseio-global-seed-us/eos-dev1/genesis.json
    echo ""

    gsutil cp blocks/blocks.log gs://dfuseio-global-seed-us/eos-dev1/blocks.log
}

main $@

