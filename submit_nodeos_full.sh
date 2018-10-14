#!/bin/bash -xe

# This step builds `nodeos` and keeps all artifacts.

_SRCTAG=${1}
if [[ ${_SRCTAG} == "" ]]; then
  echo "Missing source branch to get nodeos from!"
  exit 1
fi

_DSTTAG=${2}
if [[ ${_DSTTAG} == "" ]]; then
  _DSTTAG=${1}
fi

_PATCHES="deep-mind-v1.3.2-v8.patch deep-mind-logging-v1.3.2-v8.patch"
#_PATCHES=${3}

export CLOUDSDK_CORE_PROJECT=eoscanada-public

gcloud builds submit . \
          --config cloudbuild-nodeos-full.yaml \
          --timeout 8h \
          --substitutions "_SRCTAG=$_SRCTAG,_DSTTAG=$_DSTTAG,_PATCHES=$_PATCHES" \
          --machine-type=n1-highcpu-32
