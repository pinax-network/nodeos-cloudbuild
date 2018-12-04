#!/bin/bash -e

# This step builds `nodeos` and keeps all artifacts.

SRC="$1"
if [[ "$SRC" == "" ]]; then
  echo "Missing source branch to get nodeos from!"
  exit 1
fi

DST="$2"
if [[ "$DST" == "" ]]; then
  DST=$1
fi


PRINT=$(which cowsay >/dev/null && echo cowsay || echo echo)

$PRINT "Building Nodeos from $SRC"
./submit_nodeos_full.sh $SRC $DST
$PRINT "Building prod container for $DST"
./submit_nodeos_prod.sh $DST

PATCH=1.3.x
if echo $SRC | grep ^v1.2; then
    PATCH=1.2.x
fi
$PRINT "Building Nodeos from $SRC with deep-mind"
./submit_nodeos_full.sh $SRC $DST-deep-mind deep-mind-${PATCH}.patch
$PRINT "Building prod container for $DST-deep-mind"
./submit_nodeos_prod.sh $DST-deep-mind

$PRINT "You should now have: "
echo "-- based on EOSIO/EOS tag $SRC --"
echo "gcr.io/eoscanada-shared-services/eosio-nodeos-full:$DST for dev"
echo "gcr.io/eoscanada-shared-services/eosio-nodeos-prod:$DST for bp/peering/api nodes"

echo "-- based on EOSIO/EOS tag $SRC with deep-mind patches --"
echo "gcr.io/eoscanada-shared-services/eosio-nodeos-full:$DST-deep-mind for dev"
echo "gcr.io/eoscanada-shared-services/eosio-nodeos-prod:$DST-deep-mind for pusher nodes only"

$PRINT "Don't forget to submit manageos and pusher builds!"

curl -X POST -H 'Content-type: application/json' --data '{"text":"*New Nodeos builds produced! -- based on EOSIO/EOS tag $SRC --*
* gcr.io/eoscanada-shared-services/eosio-nodeos-full:v1.3.0 for dev
* gcr.io/eoscanada-shared-services/eosio-nodeos-prod:v1.3.0 for bp/peering/api nodes
* gcr.io/eoscanada-shared-services/eosio-nodeos-full:v1.3.0-deep-mind for dev
* gcr.io/eoscanada-shared-services/eosio-nodeos-prod:v1.3.0-deep-mind for pusher nodes only"}' https://hooks.slack.com/services/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
