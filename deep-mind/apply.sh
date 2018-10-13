#!/bin/bash -ex

SOURCE_REPO=$1
PATCH_PATH=`pwd`/$2

echo "WARNING: this will reset your source repo at $SOURCE_REPO and"
echo "all its changes, at the current branch location."
echo "It will then apply the patch at $PATCH_PATH"
echo "Press ENTER to continue."

read

cd $1

echo "Resetting $SOURCE_REPO"

git reset --hard
rm -vf libraries/chain/trace.cpp
rm -vf libraries/chain/*.orig
rm -vf libraries/chain/*.rej

echo "Resetting $SOURCE_REPO/libraries/fc"

pushd libraries/fc
git reset --hard
$(find . | grep deep_mind | xargs rm) || true
popd

echo "Applying patch $PATCH_PATH"

patch -p1 < $PATCH_PATH

echo "Done"
