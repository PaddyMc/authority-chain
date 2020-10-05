###############################################################################
###                           Basic Golang Commands                         ###
###############################################################################

install: go.sum
	go install -mod=readonly $(BUILD_FLAGS) ./cmd/authority-chaind
	go install -mod=readonly $(BUILD_FLAGS) ./cmd/authority-chaincli

install-debug: go.sum
	go build -mod=readonly $(BUILD_FLAGS) -gcflags="all=-N -l" ./cmd/authority-chaind
	go build -mod=readonly $(BUILD_FLAGS) -gcflags="all=-N -l" ./cmd/authority-chaincli

build:
	@mkdir -p build/
	@go build -mod=mod -o build/clayd ./cmd/clayd
	@go build -mod=mod -o build/claycli ./cmd/claycli

###############################################################################
###                           Chain Initialization                          ###
###############################################################################

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

###############################################################################
###                           Tests & Simulation                            ###
###############################################################################

localnet-consensus:
	./scripts/add-validator-to-validators-set.sh

localnet-start: init-dev export-key
	NODE0ADDRESS=$(shell go run cmd/authority-chaind/main.go cmd/authority-chaind/genaccounts.go tendermint show-node-id --home ./build/.authority-chaind)@192.16.10.2:26656 docker-compose up

export-key:
	echo "password1234\npassword1234" | go run cmd/authority-chaincli/main.go keys export authority-chain1 2> ./build/validator

clean:
	sudo rm -r ./build
	docker-compose down

