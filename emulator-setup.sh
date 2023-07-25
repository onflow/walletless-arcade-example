#!/bin/bash

# Generate .pkey for emulator accounts
cp emulator-account.pkey.example emulator-account.pkey
cp emulator-flow-utils.pkey.example emulator-flow-utils.pkey
cp emulator-game.pkey.example emulator-game.pkey
cp emulator-hybrid-custody.pkey.example emulator-hybrid-custody.pkey


# Create emulator-flow-utils account 0x01cf0e2f2f715450 with private key f84d8acb8a1efa87e316df886825e0b6acfa795f2599cbb306727084aa45b80d
flow accounts create --key "a45b0c0d88f7408a19cd86feef67105509aad31f5986c676cf3010fbe001e3a7b20d90d1f5bdfcb3218a6204d87dd910bc52ec32a37c1888725429d808262a1e"

# Create emulator-game account 0x179b6b1cb6755e31 with private key 884bf6b10358c23a35d272123eabb509be0e7bc895c9bfbaaeccae1b1f9204d3
flow accounts create --key "921375073cd516a5c33804ca577086501a9772f2991f9b2e28b81b62fee72f54f0ed1b7e7d4a333885dfa7de8aabc094e14bbec3aaa41895e9fe6d6f7fdb4041"

# Create emulator-hybrid-custody account 0xf3fcd2c1a78f5eee with private key 9219adbbe5caca4f2753fbd4fd22f50d5d5f6a8fe7096bbf381cbd55c2f46aab
flow accounts create --key "1dc63a08035b6c99ba1f94e2bdfa0d65c8afab71734dceb05c53cc50c6e84418258e11c9009f7983bb65bbb361150def006a4f1e14c3a032d2e4cbd0c0d19cbd"

# Transfer the game developer some $FLOW for storage fees
flow transactions send ./cadence/transactions/flow_token/transfer_flow.cdc 1000.0 0x179b6b1cb6755e31

# Deploy contracts
flow deploy

# Setup AccountCreator resource
flow transactions send ./cadence/transactions/account_creator/setup.cdc --signer emulator-game

# Setup CapabilityFactory & CapabilityFilter resources
flow transactions send ./cadence/transactions/hybrid_custody/dev_setup/setup_filter_and_factory_manager.cdc \
    0x179b6b1cb6755e31 GamePieceNFT 0x179b6b1cb6755e31 TicketToken \
    --signer emulator-game