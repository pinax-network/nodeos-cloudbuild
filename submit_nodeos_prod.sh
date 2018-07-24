#!/bin/bash -x

# This step builds `nodeos-prod` keeping only artifacts required for production.

TAG=${1}
if [[ ${TAG} == "" ]]; then
  echo "Missing branch / tag name"
  exit 1
fi

export CLOUDSDK_CORE_PROJECT=eoscanada-public

gcloud container builds submit . \
          --config cloudbuild-nodeos-prod.yaml \
          --timeout 8h \
          --substitutions COMMIT_SHA=${TAG} \
          --machine-type=n1-highcpu-32
