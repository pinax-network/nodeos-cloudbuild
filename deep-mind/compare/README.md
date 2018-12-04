Compare run
-----------

* This process takes the block logs produced by the `boot` step
* Replays it and outputs the traces to `output.log`
* Compares it to `reference.log`
* Optionally, you can pass the console logs through `capture:hlog` and
  output the archives block logs. See below.


nodeos console log reference output
-----------------------------------

Produce the output.log (compares to reference.log):

1 .Using a local `nodeos`:

```
./run.sh /path/to/your/local/nodeos
```

2 .or a Docker image with:

```
./run.sh gcr.io/eoscanada-shared-services/eosio-nodeos-prod:v1.3.2-deep-mind-v7
```

Updating the traces
-------------------

After you've inspected any difference, updated all the pipelines that
depend on changed data, update the `reference.log` by copying
`output.log` over it.  Commit it to the repo for future checks.


Test `capture:hlog` instrumentation
-----------------------------------

Run `go test -v` to produce archive logs `output.jsonl` out of the
`output.log` console logs.

The test will compare the generated output to `reference.jsonl`.
