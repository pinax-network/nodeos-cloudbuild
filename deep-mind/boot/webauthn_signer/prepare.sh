#!/bin/bash

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

current_dir="`pwd`"
trap "cd \"$current_dir\"" EXIT
pushd "$ROOT" &> /dev/null

# eosjs is a local file: dependency, so clone and build it before installing.
mkdir -p external
cd external
[ -d eosjs ] || git clone --branch="wa-experiment" https://github.com/EOSIO/eosjs.git
cd eosjs
# Upstream checkout with its own yarn.lock: Bun migrates it (same versions), so
# this install cannot be --frozen-lockfile.
bun install

cd ../..
bun install --frozen-lockfile