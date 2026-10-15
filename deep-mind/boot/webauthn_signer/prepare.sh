#!/bin/bash

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

current_dir="`pwd`"
trap "cd \"$current_dir\"" EXIT
pushd "$ROOT" &> /dev/null

bun install --frozen-lockfile
rm -rf node_modules/eosjs
mkdir -p external
cd external
git clone --branch="wa-experiment" https://github.com/EOSIO/eosjs.git
cd eosjs
bun install --frozen-lockfile

cd ../..
bun add file:external/eosjs