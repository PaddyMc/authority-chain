all: build

init-dev: init-chain init-validator

start-dev:
	go run cmd/authority-chaind/main.go cmd/authority-chaind/genaccounts.go start --home ./build/.authority-chaind

init-chain:
	go run cmd/authority-chaind/main.go cmd/authority-chaind/genaccounts.go init --chain-id=cash cash --home ./build/.authority-chaind
	echo "y" | go run cmd/authority-chaincli/main.go keys add authority-chain1 --home ./build/.authority-chaind

init-validator:
	go run cmd/authority-chaind/main.go cmd/authority-chaind/genaccounts.go add-genesis-account $(shell go run cmd/authority-chaincli/main.go keys show authority-chain1 -a --home ./build/.authority-chaind) 1000000000stake --home ./build/.authority-chaind
	go run cmd/authority-chaind/main.go cmd/authority-chaind/genaccounts.go gentx --name authority-chain1 --home ./build/.authority-chaind --moniker authority-chain --website test.com --identity test --security-contact test@test.com --details atest
	go run cmd/authority-chaind/main.go cmd/authority-chaind/genaccounts.go collect-gentxs --home ./build/.authority-chaind


build:
	@mkdir -p build/
	@go build -mod=mod -o build/clayd ./cmd/clayd
	@go build -mod=mod -o build/claycli ./cmd/claycli
