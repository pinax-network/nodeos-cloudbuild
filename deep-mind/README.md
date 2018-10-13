Deep mind patches
-----------------

Clone our private fork of EOS, checkout the right branch with submodules and perform the `git diff` command above:

```
cd /tmp
git clone --recursive git@github.com:eoscanada/eosio-eos-private.git
cd eosio-eos-private
git checkout eoscanada/deep-mind
git submodule update --recursive

git diff \
    --no-color \
    --submodule=diff \
    origin/release/1.3.x-dev eoscanada/deep-mind \
    . ':(exclude).gitmodules' \
    > ./deep-mind-1.3.x.patch
```

Alternatively checkout a fresh `eos` repo:
```
cd ~/build
git clone --recursive git@github.com:EOSIO/eos.git
cd eos
```

Follow upstream changes and apply our patch:
```
cd ~/build/eos
git submodule update --recursive
```

From this directory, run:
```
./apply.sh ~/build/eos ../patches/deep-mind-v1.3.x.patch ../patches-deep-mind-logging.patch
```

Inspect the output, test `nodeos` against `compare`, extract a new
patches with:

```
git diff --cached --ignore-submodules=all > deep-mind.patch

pushd libraries/fc
  git diff --cached --src-prefix=a/libraries/fc/ --dst-prefix=b/libraries/fc/ > ../../deep-mind-logging.patch
popd
```

Inspect the patch, make sure nothing extraneous crept in (whitespace
changes, leftovers, etc..)

Call `submit_nodeos_full.sh`


Contents
--------

* `battlefield/` holds a smart contract that can produce all our instrumentation outputs.
* `boot/` creates a blocklog that executes transactions which provokes what we have instrumented, for testing
* `compare/` allows us to replay the `boot` blocklog against any new `nodeos` releases and check that our instrumentation matches our expectations.
