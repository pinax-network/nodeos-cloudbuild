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

Testing setup
-------------

* Smart contract instrumenté avec tous les cas de génération de deferred, traces, rams, ci et ça..
* Commandes pour les builder
* Tout ce qu'il faut pour créer le block log
  * eos-bios bootseq
  * une série d'opérations, comme `eosio.forum` tests.. en utilisant `eosc`
* Assertion script & blockchain configs to enable and test deep-mind.
  * bash script qui run nodeos et qui pipe le log dans un fichier
  * un p'tit programme ou bash script qui fait des assertions sur le contenu de ce fichier (deep-mind output)
  * config.ini
* Packageable avec le blocklog, dans un container


Container
---------

* un block log à faire un replay
* assertions scripts, qui run nodeos, qui traite le output log et fait les assertions
* après chaque build de nodeos-full, ça run cette suie de test, sinon ça fail le build.. donc ça PUSH pas c't'image là.

