#!/bin/bash -xe

# This step builds `nodeos-prod` keeping only artifacts required for production.

NODEOS_FULL_TAG=v1.4.1-deep-mind-v8.2
export CLOUDSDK_CORE_PROJECT=eoscanada-public

gcloud builds submit . \
          --config cloudbuild-nodeos-prod.yaml \
          --timeout 8h \
          --substitutions _NODEOS_FULL_TAG=${NODEOS_FULL_TAG} \
          --machine-type=n1-highcpu-32
