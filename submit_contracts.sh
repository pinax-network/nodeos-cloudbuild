#!/bin/bash -x

# This step builds system contracts keeping only artifacts required for production,
# through `eosio.wasmsdk`.

export CLOUDSDK_CORE_PROJECT=eoscanada-public

gcloud builds submit . --config cloudbuild-contracts.yaml --timeout 8h --substitutions _SOURCE_BRANCH=v2 --machine-type=n1-highcpu-32
