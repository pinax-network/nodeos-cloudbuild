#!/bin/bash -xe

SHORT_SHA=`git rev-parse --short HEAD`
if [[ $? != 0 ]]; then
    echo "Unable to retrieve git short commit sha1 via 'git rev-parse --short HEAD'"
    exit 1
fi

# This step builds `bos-full` & `bos-prod` images.
export CLOUDSDK_CORE_PROJECT=eoscanada-shared-services

gcloud builds submit . \
          --config cloudbuild-bos.yaml \
          --timeout 8h \
          --machine-type=n1-highcpu-32 \
          --substitutions SHORT_SHA=${SHORT_SHA}
