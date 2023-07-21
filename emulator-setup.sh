#!/bin/bash

# Create emulator-game account 0xe03daebed8ca0615 with private key 729f42f33696b96b4c2dc75935282eb235394d5daf45a786741cb1421b8cdeb9
flow accounts create --key "70e88d5c93d76b0383f403a9e16ab5122c2f62dc38fe7255c4be2481e58823f6eab5aa24d289d4a8fb3e5b82aa787e055af7a8e309536b3203b4ce9b1fb83eb7"

# Create emulator-flow-utils account 0x045a1763c93006ca with private key 1352a6169a2db021cfc8cebc2eafaa43e5c3a586f338ac53aec8ec6522ab9387
flow accounts create --key "c83981d6c684066792432995f036d2422880b7042fc7724f5e47b7225803f880358db6fd4b8f986837d5390a2cb088768c2e3bf414b21e98b4c04f1219ae4b69"

# Create emulator-hybrid-custody account 0x120e725050340cab with private key b9f2e031cc2a6478bc52f6895c67c1cc97b12ba422fcd172d2142e2fea27b5ff
flow accounts create --key "074e64fbd0e6935d3afde1c70fc51ee0f485474b63bda28ab4fde4a7f1705e4b4d0d6af66d11f3a1ec46043cb739a276df6a6570c9b34e3b48e4ffb21cd4b155"

# Transfer Flow to game account for storage
flow transactions send ./cadence/transactions/flow_token/transfer_flow.cdc 1000.0 0xe03daebed8ca0615

# Deploy contracts
flow deploy

# Setup AccountCreator resource
flow transactions send ./cadence/transactions/account_creator/setup.cdc --signer emulator-game

# Setup CapabilityFactory & CapabilityFilter resources
flow transactions send ./cadence/transactions/hybrid_custody/dev_setup/setup_filter_and_factory_manager.cdc \
    0xe03daebed8ca0615 GamePieceNFT 0xe03daebed8ca0615 TicketToken \
    --signer emulator-game