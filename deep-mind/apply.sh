#!/bin/bash

set -e

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SOURCE_REPO=$1
DEEP_MIND_PATCH_RELATIVE=$2
DEEP_MIND_LOGGING_PATCH_RELATIVE=$3

CURRENT=`pwd`
DEEP_MIND_PATCH="`pwd`/$DEEP_MIND_PATCH_RELATIVE"
DEEP_MIND_LOGGING_PATCH="`pwd`/$DEEP_MIND_LOGGING_PATCH_RELATIVE"

REJECT=${REJECT:-"false"}

if [[ ! -d $SOURCE_REPO ]]; then
  echo "Source repository does not exist, check first argument."
  exit 1
fi

if [[ ! -f $DEEP_MIND_PATCH_RELATIVE ]]; then
  echo "Deep mind patch file does not exist, check second argument."
  exit 1
fi

if [[ ! -f $DEEP_MIND_LOGGING_PATCH_RELATIVE ]]; then
  echo "Deep mind logging patch file does not exist, check third argument."
  exit 1
fi

echo "Applying base patch:"
echo "    $DEEP_MIND_PATCH_RELATIVE (in $SOURCE_REPO)"
echo "    $DEEP_MIND_LOGGING_PATCH_RELATIVE (in $SOURCE_REPO/libraries/fc)"
echo ""

# Go back to initial directory on exit
trap "cd $CURRENT" EXIT

echo "Changing working directory to $SOURCE_REPO and applying patch"
cd $SOURCE_REPO

if [[ -n $(git status --porcelain) ]]; then
  echo "WARNING: Repository at $SOURCE_REPO is dirty, please stash or commit your changes before applying the patch"
  exit 1
fi

rm -vf libraries/chain/*.orig
rm -vf libraries/chain/*.rej

apply_args="--index --3way"
if [[ $REJECT == "true" ]]; then
  apply_args="--reject"
fi

set +e
git reset --hard
git apply ${apply_args} -p1 $DEEP_MIND_PATCH

echo "Changing working directory to $SOURCE_REPO/libraries/fc and applying patch"
cd libraries/fc

if [[ -n $(git status --porcelain) ]]; then
  echo "WARNING: Repository at $SOURCE_REPO/libraries/fc is dirty, please stash or commit your changes before applying the patch"
  exit 1
fi

git reset --hard
git apply ${apply_args} -p3 $DEEP_MIND_LOGGING_PATCH
set -e

echo "Done"
