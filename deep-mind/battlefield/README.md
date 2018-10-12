## EOS Smart Contract Boilerplate

### Building

#### Docker

The docker steps still uses the EOS.IO WASM SDK, but wrapped in a Docker container
provided to you by EOS Canada 🇨🇦.

```
docker run --rm -it -v `pwd`:/contract -w /contract gcr.io/eoscanada-public/eosio-cdt:v1.2.1 bash build.sh
```

#### EOS.IO WASM SDK

If you have the EOS.IO WASM SDK available on your machine directly, simply do the following commands:

```
./build.sh```
