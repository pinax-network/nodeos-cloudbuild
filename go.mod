module github.com/eoscanada/nodeos-cloudbuild

require (
	github.com/dfuse-io/dfuse-eosio v0.9.0-beta9.0.20211112053129-2a99c68c949c
	github.com/dfuse-io/logging v0.0.0-20210109005628-b97a57253f70
	github.com/golang/protobuf v1.5.2
	github.com/klauspost/compress v1.10.2
	github.com/lithammer/dedent v1.1.0
	github.com/manifoldco/promptui v0.8.0
	github.com/streamingfast/jsonpb v0.0.0-20210811021341-3670f0aa02d0
	github.com/stretchr/testify v1.7.0
	go.uber.org/zap v1.17.0
	golang.org/x/crypto v0.0.0-20210322153248-0c34fe9e7dc2
)

go 1.13

replace github.com/dfuse-io/dfuse-eosio => github.com/pinax-network/dfuse-eosio v0.9.0-beta9.0.20220712151257-b255ebc7c24c
