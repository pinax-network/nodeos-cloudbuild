#!/bin/bash

set -x

CLOUDSDK_CORE_PROJECT=eoscanada-shared-services \
gcloud builds submit . \
--async \
--config cloudbuild-nodeos-buildenv.yaml \
--timeout 8h
