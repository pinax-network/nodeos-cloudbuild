#!/bin/bash -xe

# This step builds `nodeos` and keeps all artifacts.

_SRCTAG="v1.4.4"
_DSTTAG="v1.4.4-hotfix"
_PATCHES="security-fix-v1.4.4.patch"

export CLOUDSDK_CORE_PROJECT=eoscanada-shared-services

gcloud builds submit . \
          --config cloudbuild-nodeos-full.yaml \
          --timeout 8h \
          --substitutions "_SRCTAG=$_SRCTAG,_DSTTAG=$_DSTTAG,_PATCHES=$_PATCHES" \
          --machine-type=n1-highcpu-32
