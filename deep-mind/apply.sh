#!/bin/bash -e

SOURCE_REPO=$1
DEEP_MIND_PATCH=`pwd`/$2
DEEP_MIND_LOGGING_PATCH=`pwd`/$3

echo "WARNING: this will reset your source repo at $SOURCE_REPO and"
echo "all its changes, at the current HEAD revision."
echo ""
echo "It will then apply the base patch at:"
echo "    $DEEP_MIND_PATCH"
echo "and the logging (libraries/fc) patch at:"
echo "    $DEEP_MIND_LOGGING_PATCH"
echo ""
echo "Press ENTER to continue."

read

cd $1

echo "Resetting $SOURCE_REPO and applying patch"

git reset --hard

#rm -vf libraries/chain/trace.cpp
#rm -vf libraries/chain/*.orig
#rm -vf libraries/chain/*.rej

git apply --index -p1 $DEEP_MIND_PATCH


echo "Resetting $SOURCE_REPO/libraries/fc"

pushd libraries/fc
git reset --hard
#$(find . | grep deep_mind | xargs rm) || true
popd

pushd libraries/fc
git apply --index -p3 $DEEP_MIND_LOGGING_PATCH
popd

echo "Done"
