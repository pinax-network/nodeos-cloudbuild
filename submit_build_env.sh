#!/bin/bash -x

# This first build step only creates the build environment, to be used by the next compile step.

export TAG=v7
export CLOUDSDK_CORE_PROJECT=eoscanada-public

gcloud container builds submit . --config cloudbuild-build-env.yaml --timeout 8h --substitutions COMMIT_SHA=${TAG} --machine-type=n1-highcpu-32
