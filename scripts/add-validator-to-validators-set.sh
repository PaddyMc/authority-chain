#!/bin/sh

###############################################################################
###                           FUNCTIONS		                            ###
###############################################################################

# Creates a validator for a given node
# Take 1 arg the name of the node e.g authority-chaindnode0
createValidator() {
	echo "Creating validator for node $1\n"

	# Create the validator
	docker exec -e MONIKER=$1 $1 /bin/sh -c 'authority-chaincli tx poa create-validator $(authority-chaincli keys show validator --bech val -a --keyring-backend test) $(authority-chaind tendermint show-validator) $(echo $MONIKER) identity website security@contact details -y --trust-node --from validator --chain-id cash --keyring-backend test'

	sleep 5
}

# Votes for a perspecitve canidate
# Take 2 args the name of the node voting and the candidate node e.g authority-chaindnode0 authority-chaindnode1
voteForValidator() {
	eval CANDIDATE=$(docker exec $2 /bin/sh -c "authority-chaincli keys show validator --bech val -a --keyring-backend test")
	echo "Voter $1 is voting for candidate $2"
	docker exec -e CANDIDATE=$CANDIDATE $1 /bin/sh -c 'authority-chaincli tx poa vote-validator $(echo $CANDIDATE) -y --trust-node --from validator --chain-id cash --keyring-backend test'

	sleep 5
}

# Kicks for a perspecitve canidate
# Take 2 args the name of the node voting and the candidate node e.g authority-chaindnode0 authority-chaindnode1
kickValidator() {
	eval CANDIDATE=$(docker exec $2 /bin/sh -c "authority-chaincli keys show validator --bech val -a --keyring-backend test")
	echo "Votee $1 is voting to kick candidate $2"
	docker exec -e CANDIDATE=$CANDIDATE $1 /bin/sh -c 'authority-chaincli tx poa kick-validator $(echo $CANDIDATE) -y --trust-node --from validator --chain-id cash --keyring-backend test'

	sleep 5
}
###############################################################################
###                           STEP 1		                            ###
###############################################################################

# Import the exported key for the first node
docker exec authority-chaindnode0 /bin/sh -c "echo -e 'password1234\n' | authority-chaincli keys import validator validator --keyring-backend test"

## Create the validator
voteForValidator authority-chaindnode0 authority-chaindnode0

###############################################################################
###                           STEP 2		                            ###
###############################################################################

# Create the keys for each node
for var in authority-chaindnode1 authority-chaindnode2 authority-chaindnode3
do
	echo "Creating key for node $var\n"
	docker exec $var /bin/sh -c "authority-chaincli keys add validator --keyring-backend test"
done


## Send tokens to each validator
for node in authority-chaindnode1 authority-chaindnode2 authority-chaindnode3
do
	eval ADDRESS=$(docker exec $node /bin/sh -c "authority-chaincli keys show validator -a --keyring-backend test")
	echo "Sending tokens to $ADDRESS\n"
	docker exec -e ADDRESS=$ADDRESS authority-chaindnode0 /bin/sh -c 'authority-chaincli tx send $(authority-chaincli keys show validator -a --keyring-backend test) $(echo $ADDRESS) 100000stake -y --trust-node --from validator --chain-id cash --keyring-backend test'
	sleep 5
done

###############################################################################
###                           STEP 3		                            ###
###############################################################################

# Create validator for validator set
for var in authority-chaindnode1 authority-chaindnode2 authority-chaindnode3
do
	createValidator $var
done

###############################################################################
###                           STEP 4		                            ###
###############################################################################

# Adding new validators to the set

# Vote for validator1 to join the set
voteForValidator authority-chaindnode0 authority-chaindnode1

# authority-chaindnode1 votes for authority-chaindnode0 to prove the node is in the consensus
voteForValidator authority-chaindnode1 authority-chaindnode0

# authority-chaindnode1 votes for authority-chaindnode1 to stay relevant in the consensus
voteForValidator authority-chaindnode1 authority-chaindnode1

# authority-chaindnode1 and poanode0 votes for authority-chaindnode2 to join the consensus
voteForValidator authority-chaindnode0 authority-chaindnode2
voteForValidator authority-chaindnode1 authority-chaindnode2

# authority-chaindnode2 votes for authority-chaindnode2 to stay relevant in the consensus
voteForValidator authority-chaindnode2 authority-chaindnode2

# authority-chaindnode2 votes for authority-chaindnode1 to prove the node is in the consensus
voteForValidator authority-chaindnode2 authority-chaindnode1

# authority-chaindnode2 votes for authority-chaindnode0 to prove the node is in the consensus
voteForValidator authority-chaindnode2 authority-chaindnode0

# kick authority-chaindnode2 out of the consensus
kickValidator authority-chaindnode0 authority-chaindnode2
kickValidator authority-chaindnode1 authority-chaindnode2

echo "POA Consensus started with 2 nodes :thumbs_up:\n"

sleep 5

## Verify valdiators are in the set by checking the validator set
docker exec authority-chaindnode0 /bin/sh -c "curl -X GET 'localhost:26657/validators'"
