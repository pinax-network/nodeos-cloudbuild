#!/bin/bash -xe

# This step builds `bos-full` & `bos-prod` images.
export CLOUDSDK_CORE_PROJECT=eoscanada-shared-services

gcloud builds submit . \
          --config cloudbuild-bos-deepmind.yaml \
          --timeout 8h \
          --machine-type=n1-highcpu-32
