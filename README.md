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
