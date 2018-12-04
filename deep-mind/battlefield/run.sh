#!/bin/bash

docker run --rm -it -v `pwd`:/contract -w /contract gcr.io/eoscanada-shared-services/eosio-cdt:v1.2.1 bash build.sh
