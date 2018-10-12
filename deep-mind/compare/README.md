Compare run
-----------

* This process takes the block logs produced by the `boot` step
* Replays it and outputs the traces to `output.log`
* Compares it to `reference.log`


Run with
--------

Using a local `nodeos`:

```
./run.sh /path/to/your/local/nodeos
```

or a Docker image with:

```
./run.sh gcr.io/eoscanada-public/eosio-nodeos-prod:v1.3.2-deep-mind-v7
```


Updating the traces
-------------------

After you've inspected any difference, updated all the pipelines that
depend on changed data, update the `reference.log` by copying
`output.log` over it.  Commit it to the repo for future checks.
