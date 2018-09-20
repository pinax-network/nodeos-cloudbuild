#!/bin/bash -x

# This first build step only creates the build environment, to be used by the next compile step.

export TAG=v1.1.1
export EOS_WASMSDK_VERSION=v1.1.1
export CLOUDSDK_CORE_PROJECT=eoscanada-public

gcloud builds submit . --async --config cloudbuild-wasmsdk.yaml --disk-size 120 --timeout 8h --substitutions "COMMIT_SHA=${TAG},_EOS_WASMSDK_VERSION=${EOS_WASMSDK_VERSION}" --machine-type=n1-highcpu-32
