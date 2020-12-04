#!/bin/bash

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export CLOUDSDK_CORE_PROJECT=eoscanada-shared-services

gcloud builds submit . --config eosio-cdt.cb.yaml --machine-type=n1-highcpu-32 --async
