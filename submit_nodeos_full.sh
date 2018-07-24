#!/bin/bash -x

# This step builds `nodeos` and keeps all artifacts.

TAG=${1}
if [[ ${TAG} == "" ]]; then
  echo "Missing branch / tag name"
  exit 1
fi

export CLOUDSDK_CORE_PROJECT=eoscanada-public
COMMIT_SHA=${TAG}
BRANCH=${TAG}

gcloud container builds submit . \
          --config cloudbuild-nodeos-full.yaml \
          --timeout 8h \
          --substitutions COMMIT_SHA=$COMMIT_SHA,_BRANCH=$BRANCH \
          --machine-type=n1-highcpu-32
