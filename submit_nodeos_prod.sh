#!/bin/bash -xe

# This step builds `nodeos-prod` keeping only artifacts required for production.

NODEOS_FULL_TAG=${1}
if [[ ${NODEOS_FULL_TAG} == "" ]]; then
  echo "Missing nodeos-full tag to use!"
  exit 1
fi

export CLOUDSDK_CORE_PROJECT=eoscanada-public

gcloud builds submit . \
          --config cloudbuild-nodeos-prod.yaml \
          --timeout 8h \
          --substitutions _NODEOS_FULL_TAG=${NODEOS_FULL_TAG} \
          --machine-type=n1-highcpu-32
