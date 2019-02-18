Deep mind patches
-----------------

Checkout a fresh `eos` repo:
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


Local development
-----------------

In (or around) your `eos` checkout, run:

    docker run --name eos-buildenv -ti -v `pwd`:`pwd` -w `pwd` gcr.io/eoscanada-shared-services/eosio-build-env:v7 /bin/bash

and from within:

    cd eos
    ./eosio_build.sh

Output is in `eos/build/programs/nodeos/nodeos`.  You can use that in `boot` and `compare`.


Publish build
-------------

Inspect the patch, make sure nothing extraneous crept in (whitespace
changes, leftovers, etc..)

Call `submit_nodeos_full.sh`


Contents
--------

* `battlefield/` holds a smart contract that can produce all our instrumentation outputs.
* `boot/` creates a blocklog that executes transactions which provokes what we have instrumented, for testing
* `compare/` allows us to replay the `boot` blocklog against any new `nodeos` releases and check that our instrumentation matches our expectations.
