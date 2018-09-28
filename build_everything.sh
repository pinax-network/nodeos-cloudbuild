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

$PRINT "Building Nodeos from $SRC with deep-mind"
./submit_nodeos_full.sh $SRC $DST-deep-mind deep-mind-1.3.x.patch
$PRINT "Building prod container for $DST-deep-mind"
./submit_nodeos_prod.sh $DST-deep-mind

$PRINT "You should now have: "
echo "-- based on EOSIO/EOS tag $SRC --"
echo "gcr.io/eoscanada-public/eosio-nodeos-full:$DST for dev"
echo "gcr.io/eoscanada-public/eosio-nodeos-prod:$DST for bp/peering/api nodes"

echo "-- based on EOSIO/EOS tag $SRC with deep-mind patches --"
echo "gcr.io/eoscanada-public/eosio-nodeos-full:$DST-deep-mind for dev"
echo "gcr.io/eoscanada-public/eosio-nodeos-prod:$DST-deep-mind for pusher nodes only"
