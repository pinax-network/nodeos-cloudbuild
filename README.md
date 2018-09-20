Build environments and images
-----------------------------


* Dockerfile-build-env: holds all the compilers and libraires needed to build `eosio`.
  * Dockerfile-nodeos-full: builds a given tag of `eosio`, and keeps all the build environment, artifacts, header files and installed components.
    * Dockerfile-nodeos-prod: plucks out of an `Dockerfile-nodeos-full`-produced image, only what is necessary to run `nodeos` in production.
    * Dockerfile-contracts: uses the `Dockerfile-nodeos-full` environment to build smart contracts for a given tag of `eosio`.



Each time there's a new tag
---------------------------

```
./submit_nodeos_full.sh
```

Patches
-----------------------------

The `full` build has some custom patches that we developed that we did not upstream yet (and we might never upstream them). The purpose of
this section is to give you a quick step-by-step to build the patch files.

Deep Mind
------------------------------

Clone our private fork of EOS, checkout the right branch with submodules and perform the `git diff` command above:

```
cd /tmp
git clone --recursive git@github.com:eoscanada/eosio-eos-private.git
git checkout eoscanada/deep-mind
git submodule update --recursive

git diff --submodule=diff --no-color origin/release/1.3.x-dev eoscanada/deep-mind > ./deep-mind-1.3.x.patch
```
