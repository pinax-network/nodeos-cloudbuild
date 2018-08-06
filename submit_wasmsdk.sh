#!/bin/bash -x

# This first build step only creates the build environment, to be used by the next compile step.

export TAG=v2

gcloud builds submit . --project eoscanada-public --config cloudbuild-wasmsdk.yaml --disk-size 120 --timeout 8h --substitutions COMMIT_SHA=${TAG} --machine-type=n1-highcpu-32
