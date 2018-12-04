#!/bin/bash -xe

# This step builds `nodeos` and keeps all artifacts.

_SRCTAG="v1.4.4"
_DSTTAG="v1.4.4-deep-mind-v8.2"
_PATCHES="deep-mind-v1.4.4-v8.2.patch deep-mind-logging-v1.4.4-v8.2.patch"

export CLOUDSDK_CORE_PROJECT=eoscanada-shared-services

gcloud builds submit . \
          --config cloudbuild-nodeos-full.yaml \
          --timeout 8h \
          --substitutions "_SRCTAG=$_SRCTAG,_DSTTAG=$_DSTTAG,_PATCHES=$_PATCHES" \
          --machine-type=n1-highcpu-32
