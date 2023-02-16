# Rock Paper Scissors (Mostly) On-Chain

> :warning: This repo is a WIP aiming to showcase how Auth Account capabilities from [FLIP 53](https://github.com/onflow/flips/pull/53) could be use to achieve hydrid custody

> We’re building an on-chain Rock Paper Scissors game as a proof of concept exploration into the world of blockchain gaming powered by Cadence on Flow.

## Overview

As gaming makes its way into Web 3.0, bringing with it the next swath of mainstream users, we created this repo as a playground to develop proof of concept implementations that showcase the power of on-chain games built with the Cadence resource-oriented programming language. Through this exploration, we discovered the importance of improving onboarding, reducing friction in dApp user experience, and so iterated our way to a working hybrid custody model. It's our hope that the work and exploration here uncovers unique design patterns that are useful towards composable game designs and, more broadly, novel dApp custody models, helping to pave the way for a thriving community of developers building the best dApps in the world on Flow.

For our first proof of concept game, we've created the `RockPaperScissorsGame` and supporting contract `GamingMetadataViews`. Taken together with any NFT (`MonsterMaker` as an example), these contracts define an entirely on-chain game with a dynamic NFT that accesses an ongoing record of its win/loss data via native Cadence attachments added to the NFT upon escrow.

As this proof of concept has been iteratively improved, we've created a host of reference examples demonstrating how game developers could build games on Flow - some entirely on-chain while others blend on and off-chain architectures along with considerations for each design. The repo you're viewing places focus on on-chain, player-mediated gameplay along with support for linked accounts (AKA hybrid custody model).

We believe that smart contract-powered gaming is not only possible, but that it will add to the gaming experience and unlock totally new mechanisms of gameplay. Imagine a world where games require minimal, if any, backend support - just a player interfacing with an open-sourced local client making calls to a smart contract. Player's get maximum transparency, trustlessness, verifiability, and total ownership of their game assets. By leveraging the new [hybrid custody model](https://flow.com/post/flow-blockchain-mainstream-adoption-easy-onboarding-wallets) enabled in this repo and implemented in [@onflow/flow-games-retro](https://github.com/onflow/flow-games-retro), the UX and custodial challenges inherent to building on-chain games are alleviated, empowering developers to push the boundaries of in-game asset ownership, platform interoperability, and data & resource composability.

With a community of open-source developers building on a shared blockchain, creativity could be poured into in-game experiences via community supported game clients while all players rest assured that their game assets are secured and core game logic remains unchanged. Game leaderboards emerge as inherent to the architecture of a publicly queryable blockchain, and eventually efficient Access Node querying. Game assets and logic designed for use in one game can be used as building blocks in another, while matches and tournaments could be defined to have real stakes and rewards.

The entirety of that composable gaming future is possible on Flow, and starts with the simple proof of concept defined in this repo. We hope you dive in and are inspired to build more fun and complex games using the learnings, patterns, and maybe even resources in these contracts!

### Gameplay Overview

To showcase this promised composability, we constructed contracts to support a multi-dApp experience starting with a game of Rock, Paper, Scissors (RPS). Straightforward enough, players can engage in single or two-player single round matches of RPS. After configuring their `GamePlayer` resource, they can start a match by escrowing any NFT. The match is playable once both players have escrowed their NFTs (or after the first player to escrow if in single player mode). The escrowed NFT gets an attachment that retrieves its win/loss record and another that maintains the playable moves for the game - rock, paper, and scissors, as expected.

Once playable, the match proceeds in stages - commit and resolve (to be replaced by a commit-reveal pattern to obfuscate on-chain moves). Players first must commit their moves. After both players have submitted moves, the match can be resolved. On resolution, a winner is determined and the associated NFT's win/loss record is amended with the match results. Of course, once the match is over (or if a timeout is reached without resolution) the escrowed NFTs can then be returned to their respective escrowing players.

The [game dApp demo](https://github.com/onflow/walletless-arcade-example) showcases how developers can build on these contracts to create novel in-game experiences using the hybrid custody model. To facilitate a fuller game experience, `TicketToken` was introduced to be awarded on wins, just like an arcade. After onboarding a user with a hybrid custody model implementation, a dApp can perform all actions without requiring a single user signature all while the user maintains full access to the app account via delegated AuthAccount Capability.

The accompanying `TicketToken` and `ArcadePrize` contracts aren't special in and of themselves - simple FT and NFT contracts. However, once a user links their wallet with the app account used to play `RockPaperScissorsGame` - the account issued `TicketToken` on match wins - the authenticated account is issued an AuthAccount Capability on the app account. This on-chain linking between accounts establishes what we'll call a "parent-child" hierarchy between user accounts where the user's wallet mediated account is the "parent" to the partitioned "child" account.

After linking, the user can authenticate in a dApp using their parent account, and any dApp leveraging the resources in the `ChildAccount` contract can identify all associated child accounts, their contents, and facilitate transactions interacting with child-account custodied assets with a transaction signed by the parent account alone.

To demonstrate this, `ArcadePrize` accepts `TicketToken` redemption for minting NFTs. Redeeming FTs for NFTs isn't new, but the ability to sign a transaction with one account and, using delegated AuthAccount Capabilities, acquire funds from another to mint an NFT to the signing account is new. This setup introduces account models similar to Web2's app authorization into our decentralized Web3 context.

This small use case unlocks a whole world of possibilities, merging walled garden custodial dApps with self-custodial wallets enabling ecosystem-wide composability and unified asset management. Users can engage with hybrid custody apps seamlessly, then leave their assets in app accounts, sign into a marketplace and redeem in-app currencies and NFTs without the need to first transfer to the account they plan on spending or listing from.

## Components

### **Summary**

As mentioned above, the supporting contracts for this game have been compartmentalized to four primary contracts. At a high level, those are:

#### **Gaming**
* **GamingMetadataViews** - Defining the metadata structs relevant to an NFT's win/loss data and assigned moves as well as interfaces designed to be implemented as attachments for NFTs.

* **RockPaperScissorsGame** - As you might imagine, this contract contains the game's moves, logic as well as resources and interfaces defining the rules of engagement in the course of a match. Additionally, receivers for Capabilities to matches are defined in `GamePlayer` resource and interfaces that allow players to create matches, be added and add others to matches, and engage with the matches they're in. The `Match` resource is defined as a single round of Rock, Paper, Scissors that can be played in either single or two player modes, with single-player modes randomizing the second player's move on a contract function call.

#### **Linked Accounts**
* **ChildAccount** - The resources enabling the "parent-child" account hierarchical model are defined within this contract. `ChildAccountCreator` can be used to create app accounts, funding creation by the signer and tagging accounts with pertinent metadata (`ChildAccountInfo`) in a `ChildAccountTag`. A parent account maintains a `ChildAccountManager` which captures any linked child accounts' `AuthAccount` and `ChildAccountTag` Capabilities in a `ChildAccountController`, indexing the nested resource on the child account's address.

#### **Supporting**
* **MonsterMaker** - An example NFT implementation, [seen elsewhere](https://monster-maker-web-client.vercel.app/) in Flow demos, used to demonstrate NFT escrow in `RockPaperScissorsGame` gameplay.
* **TicketToken** - A simple FungibleToken implementation intended for use as redemption tokens in exchange for `ArcadePrize` NFTs
* **ArcadePrize** - Another example implementation, this time of a NonFungibleToken. Minting requires `TicketToken` redemption. An interesting note, you can redeem

### **Composition**
Taking a look at Rock Paper Scissors, you'll see that it stands on its own - a user with any NFT can engage with the game to play single and multiplayer matches. The same goes for TicketTokens and MonsterMaker contracts in that they are independent components not necessarily designed to be used together. We created each contract as a composable building block and put them together to create a unique [game dApp demo](https://github.com/onflow/walletless-arcade-example), incorporating ChildAccounts as a middle layer abstracting user identity from a single account to a network of associated accounts. 

___

## Happy Path User Walkthrough

With the context and components explained, we can more closely examine how they interact in a full user interaction. For simplicity, we'll assume everything goes as it's designed and walk the happy path.

### **Onboarding**
With linked accounts, there are two ways a user can onboard. First, a dApp can onboard a user with Web2 credentials, creating a Flow account for the user and abstracting away key management. We'll call this "Wallet-less" onboarding. Second, a user native to the Flow ecosystem can connect their wallet and start the dApp experience with controll over the app account. In our version, the dApp will still abstract key management, but will additionally delegate control over the app account to the user's authenticated account via AuthAccount Capabilities. We'll call this the "blockchain-native" onboarding flow.

**Wallet-less Onboarding**
1. After a user authenticates via some traditional Web2 authentication mechanism, the dApp initiates walletless onboarding
    1. A new public/private key pair is generated
    1. Providing the generated public key, app account metadata, and MonsterMaker components, the walletless onboarding transaction starts by creating a new account from the signer's `ChildAccountCreator` resource
    1. A MonsterMaker Collection is configured in the new account
    1. The signer mints a MonsterMaker NFT to the new account's Collection
    1. A GamePlayer resource is configured in the new account so it can play RockPaperScissorsGame Matches
    1. A TicketToken Vault is saved & linked in the new account

**Blockchain-native Onboarding**
1. After user's wallet has been connected, run the blockchain-native multisig onboarding transaction signed by both a developer account & the user. Note that this would require a backend account pre-configured with a `ChildAccountCreator` & funded with FLOW to pay for new account creation - more on this in the Flow CLI demo walkthrough. This onboarding transaction does the following.
    1. Given a generated public key (private key managed by the game dev)
    1. Creates a new account
    1. Links an AuthAccount Capability in the new account's private storage
    1. Configures the account with a MonsterMaker Collection
    1. Configures the new account with a GamePlayer resource
    1. Sets up a TicketToken Vault in the new account
    1. Sets up MonsterMaker collection in the user's connected account
    1. Sets up a TicketToken Vault in the user's connected account
    1. Configures a `ChildAccountManager` in the user's account
    1. Mints a MonsterMaker NFT to the new account's Collection
    1. Links the new account as a child of the user's account via the configured `ChildAccountManager`, giving the user delegated access of the newly created account

### Gameplay

1. Single-Player Gameplay
    1. Player creates a new match, escrowing their NFT along with their NFT `Receiver`, emitting `NewMatchCreated` and `PlayerEscrowedNFTToMatch`. Note that match timeout is established on creation, which prevents the escrowed NFT from being retrieved during gameplay.
        1. `RPSAssignedMoves` are attached to their escrowed NFT if they are not already attached
        1. `RPSWinLossRetriever` is attached to the escrowed NFT if they are not already attached
    1. Player submits their move
        1. `MoveSubmitted` event is emitted with relevant `matchID` and `submittingGamePlayerID`
    1. Player calls for automated player's move to be submitted
        1. `MoveSubmitted` event is emitted with relevant `matchID` and `submittingGamePlayerID` (the contract's designated `GamePlayer.id` in this case)
    1. In a separate transaction (enforced by block height), player calls `resolveMatch()` to determine the outcome of the `Match`
        1. The win/loss record is recorded for the player's NFT
        1. The win/loss record is recorded for the designated contract's `dummyNFTID`
        1. The escrowed NFT is returned to the escrowing player
        1. `MatchOver` is emitted along with the `matchID`, `winningGamePlayerID`, and `winningNFTID`.
    1. Player calls for escrowed NFT to be returned via `returnPlayersNFTs()`. Since the `Match` returns the escrowed NFTs directly via the given `Receiver` Capability, we made this a separate call to prevent malicious Capabilities from disallowing resolution. In this case, the worst a malicious Capability could do would be force the other player to call `retrieveUnclaimedNFT()` in order to have their NFT returned.
1. Multi-Player Gameplay
    1. Player one creates a new match, escrowing their NFT. Note that match timeout is established on creation, which prevents the escrowed NFT from being retrieved during gameplay.
        1. `RPSAssignedMoves` are attached to their escrowed NFT if they are not already attached
        1. `RPSWinLossRetriever` is attached to the escrowed NFT if they are not already attached
    1. Player one adds `MatchLobbyActions` Capability to Player two's `GamePlayerPublic`
        1. Player one gets `GamePlayerPublic` Capability from Player two
        1. Player one calls `addPlayerToMatch()` on their `GamePlayer`, passing the `matchID` and the reference to Player two's `GamePlayerPublic`
        1. `PlayerAddedToMatch` emitted along with matchID and the `id` of the `GamePlayer` added to the Match
    1. Player two escrows their NFT into the match
        1. `RPSAssignedMoves` are attached to their escrowed NFT if they are not already attached
        1. `RPSWinLossRetriever` is attached to the escrowed NFT if they are not already attached
    1. Each player submits their move
    1. After both moves have been submitted, any player can then call for match resolution
        1. A winner is determined
        1. The win/loss records are recorded for each NFT
        1. Each NFT is returned to their respective owners
        1. `MatchOver` is emitted along with the `matchID`, `winningGamePlayerID`, `winningNFTID` and `returnedNFTIDs`
    1. Any player calls for escrowed NFT to be returned via `returnPlayersNFTs()`. Since the `Match` returns the escrowed NFTs directly via the given `Receiver` Capability, we made this a separate call to prevent malicious Capabilities from disallowing resolution. In this case, the worst a malicious Capability could do would be to require that the other player call `retrieveUnclaimedNFT()` in a separate transaction to retrieve their singular NFT from escrow.

___

## Edge Case Resolution

#### **NFTs are escrowed, but the moves are never submitted**

Since a match timeout is specified upon `Match` creation and retrieval of `NFT`s is contingent on either the timeout being reached or the `Match` no longer being in play, a player can easily retrieve their `NFT` after timeout by calling `returnPlayerNFTs()` on their `MatchPlayerActions` Capability.

Since this Capability is linked on the game contract account which shouldn’t not have active keys, the user can be assured that the Capability will not be unlinked. Additionally, since the method deposits the `NFT` to the `Receiver` provided upon escrow, they can be assured that it will not be accessible to anyone else calling `returnPlayerNFTs()`.

#### **NFTs are escrowed, but player unlinks their `Receiver` Capability before the NFT could be returned**

In this edge case, the `Receiver` Capability provided upon escrowing would no longer be linked to the depositing player’s `Collection`. In this case, as long as the escrowing player still has their `GamePlayer`, they could call `retrieveUnclaimedNFT()`, providing a reference to their `GamePlayerID` and the `Receiver` they want their NFT returned to.

#### **Player provides a Receiver Capability that panics in its deposit() method**

This wouldn't be encounterd by the `Match` until `returnPlayerNFTs()` is called after match resolution. Depending on the order of the `Receiver` Capabilities in the `nftReceivers` mapping, this could prevent the other player from retrieving their NFT via that function. At that point, however, the winner & loser have been decided and the game is over (`inPlay == false`). The other player could then call `retrieveUnclaimedNFT()` to retrieve the NFT that the trolling Receiver was preventing from being returned.

#### **Player changes their mind after NFT escrow & before move submission**

In the event a player changes their mind after creating a match, they'd currently have to wait the length of timeout to call `returnPlayerNFTs()`. Changing this behavior is scoped as a future improvement to enable abandoning a match before initiating gameplay, likely only to be updated in singleplayer mode matches.
___

## Demo on Emulator Using Flow CLI

To demo the functionality of this repo, clone it and follow the steps below by entering each command using [Flow CLI](https://github.com/onflow/flow-cli/releases/tag/v0.45.1-cadence-attachments-3) (Attachments/AuthAccount Capability pre-release version) from the package root:

### Pre-Requisites

- Start the emulator
    
    ```sh
    flow emulator start
    ```
    
- Create the game developer account
    
    ```sh
    flow accounts create # account name: game-dev
    ```
    
- Add the game dev contracts to the flow.json. Your deployments section should look like:
    
    ```json
    "deployments": {
        "emulator": {
            "emulator-account": [
                "NonFungibleToken",
                "MetadataViews",
                "FungibleTokenMetadataViews",
                "ChildAccount",
                "GamingMetadataViews",
                "MonsterMaker"
            ],
            "game-dev": [
                "TicketToken",
                "ArcadePrize",
                "RockPaperScissorsGame"
            ]
        }
    }
    ```
    
- Deploy the contracts
    
    ```sh
    flow deploy
    ```
    
- Configure the game dev account
    - `ChildAccountCreator` resource configured & `ChildAccountCreatorPublic` Capability linked
        - `child_account/setup_child_account_creator`
        
        ```sh
        flow transactions send transactions/child_account/setup_child_account_creator.cdc --signer game-dev
        ```
        
    - `FlowToken` balance to fund new account creation
        
        ```sh
        flow transactions send transactions/flowToken/mint_tokens.cdc 01cf0e2f2f715450 <AMOUNT>
        ```
        
    - `MonsterMaker.NFTMinter` Capability has been published by the [deployment account](https://testnet.flowscan.org/account/0xfd3d8fe2c8056370) for the game dev backend account and claimed by that account. This is due to how the MonsterMaker minter was configured and that it is already deployed to testnet.
        
        ```sh
        flow transactions send transactions/monster_maker/publish_nft_minter_capability.cdc <CAPABILITY_NAME> <RECEIVER_ADDRESS>
        ```
        
        ```sh
        flow transactions send transactions/monster_maker/claim_nft_minter_capability.cdc <CAPABILITY_NAME> <PROVIDER_ADDRESS> --signer game-dev
        ```

### Walletless Demo Walkthrough

#### **Onboarding**

1. Generate public/private key pair
    
    ```sh
    flow keys generate
    ```
    
2. Initialize walletless onboarding
    * `onboarding/walletless_onboarding`
        1. `pubKey: String,`
        2. `fundingAmt: UFix64,`
        3. `childAccountName: String,`
        4. `childAccountDescription: String,`
        5. `clientIconURL: String,`
        6. `clientExternalURL: String,`
        7. `monsterBackground: Int,`
        8. `monsterHead: Int,`
        9. `monsterTorso: Int,`
        10. `monsterLeg: Int`
    
    ```sh
    flow transactions send transactions/onboarding/walletless_onboarding.cdc <PUBLIC_KEY> <FUNDING_AMT> <CHILD_ACCOUNT_NAME> <CHILD_ACCOUNT_DESC> <CLIENT_ICON_URL> <CLIENT_EXT_URL> <BACKGROUND> <HEAD> <TORSO> <LEG> --signer game-dev
    ```
    
3. Query for new account address from public key
    * `child_account/get_child_address_from_public_key_on_creator: Address`
        1. `creatorAddress: Address`
        2. `pubKey: String`
    
    ```sh
    flow scripts execute scripts/child_account/get_child_address_from_public_key_on_creator.cdc 01cf0e2f2f715450 <PUBLIC_KEY>
    ```
    
4. Add the child account to your flow.json (assuming following along on flow-cli)
    
    ```json
    "accounts": {
        "emulator-account": {
            "address": "f8d6e0586b0a20c7",
            "key": "<EMULATOR_ACCOUNT_PRIVATE_KEY>"
        },
        "game-dev": {
            "address": "01cf0e2f2f715450",
            "key": "<GAME_DEV_PRIVATE_KEY>"
        },
        "child": {
            "address": "179b6b1cb6755e31",
            "key": "<CHILD_PRIVATE_KEY>"
        }
    }
    ```
#### **Gameplay**

1. Query for `NFT.id` 
    * `game_piece_nft/get_collection_ids: [UInt64]`
        * `address: Address`
    
    ```sh
    flow scripts execute scripts/monster_maker/get_collection_ids.cdc 179b6b1cb6755e31
    ```
    
2. Query for `GamePlayer.id`
    * `rock_paper_scissors_game/get_game_player_id: UInt64`
        * `playerAddress: Address`
    
    ```sh
    flow scripts execute scripts/rock_paper_scissors_game/get_game_player_id.cdc 179b6b1cb6755e31
    ```
    
3. Setup a new singleplayer `Match`
    * `rock_paper_scissors_game/game_player/setup_new_singleplayer_match`
        1. `submittingNFTID: UInt64`
        2. `matchTimeLimitInMinutes: UInt`
    
    ```sh
    flow transactions send transactions/rock_paper_scissors_game/game_player/setup_new_singleplayer_match.cdc <NFT_ID> <TIME_LIMIT> --signer child
    ```
    
4. Query `Match.id`
    1. Listen for `NewMatchCreated` event filtered on `creatorID == GamePlayer.id`
    2. `rock_paper_scissors_game/get_matches_in_play: [UInt64]`
        * `address: Address`
    
    ```sh
    flow scripts execute scripts/rock_paper_scissors_game/get_matches_in_play.cdc 179b6b1cb6755e31 
    ```
    
5. Submit moves for the `Match`
    * `rock_paper_scissors_game/game_player/submit_both_singleplayer_moves`
        1. `matchID: UInt64`
        2. `move: UInt8`
    
    ```sh
    flow transactions send transactions/rock_paper_scissors_game/game_player/submit_both_singleplayer_moves.cdc <MATCH_ID> <MOVE> --signer child
    ```
    
6. Resolve `Match` & return escrowed NFTs
    * `rock_paper_scissors_game/game_player/resolve_match_and_return_nfts`
        * `matchID: UInt64`
    
    ```sh
    flow transactions send transactions/rock_paper_scissors_game/game_player/resolve_match_and_return_nfts.cdc <MATCH_ID> --signer child
    ```
    
7. Query move history for both players one of a number of ways:
    1. Listen for `MatchOver` event filtered on `matchID == Match.id` and map user’s `GamePlayer.id` to `player1ID` or `player2ID` in the event values, displaying the `player1MoveRawValue` and `player2MoveRawValue` as appropriate
    2. `rock_paper_scissors_game/get_match_move_history: {UInt64: RockPaperScissorsGame.SubmittedMove}?`
        * `matchID: UInt64`
        
        ```sh
        flow scripts execute scripts/rock_paper_scissors_game/get_match_move_history.cdc <MATCH_ID>
        ```
        
    3. `rock_paper_scissors_game/get_match_move_history_as_raw_values: {UInt64: UInt8}?`
        * `matchID: UInt64`
        
        ```sh
        flow scripts execute scripts/rock_paper_scissors_game/get_match_move_history_as_raw_values.cdc <MATCH_ID>
        ```
        
8. Query player’s NFT win/loss record
    * `game_piece_nft/get_rps_win_loss: GamingMetadataViews.BasicWinLoss?`
        1. `address: Address`
        2. `id: UInt64`
        
        ```sh
        flow scripts execute scripts/monster_maker/get_rps_win_loss.cdc 179b6b1cb6755e31 <NFT_ID>
        ```

#### **Connect Wallet & Link Accounts**

There are two ways to go about this process. One involves a multi-signature transaction where both the existing app account (soon to be “child” account) and the user’s main account (soon to be “parent” account) sign a transaction in which all changes are made. Another approach is to have the app account sign a transaction publishing its AuthAccount capability to then be claimed by the user’s account in a subsequent transaction.

For both the following transaction, you'll want to create an account if following along in flow-cli

```sh
flow accounts create # account name: parent
```

**Multi-Sig**

1. Both accounts sign a transaction, configuring a `ChildAccountManager` in the user’s main account and capturing the child account’s AuthAccount capability in said `ChildAccountManager`. The `GamePlayer` resource in the child account is moved to the now parent account and a `DelegatedGamePlayer` capability is granted to the child account, saved in it `ChildAccountTag`. 
In the end, the two accounts are linked by resource representation on-chain and both are configured such that the app has all it needs to play the game on behalf of the player and the user’s main account (AKA parent account) maintains an AuthAccount capability on the app account (AKA child account) so resources can be transferred from the child account without need for the app’s involvement.
    
    * `multisig_add_as_child`
    
        ```bash
        flow transactions build transactions/child_account/add_as_child_multisig.cdc --proposer parent --payer parent --authorizer parent --authorizer child --filter payload --save add_as_child_multisig
        ```
        
        ```bash
        flow transactions sign add_as_child_multisig --signer parent --signer child --filter payload --save add_as_child_multisig
        ```
        
        ```bash
        flow transactions send-signed add_as_child_multisig
        ```
    
2. Alternatively, if we want to move the NFT from the child account to the parent’s Collection while linking, we can run the following
ℹ️ Note: This transaction makes all checks necessary to configure the parent account with Collection & ChildAccountManager resources & capabilities. It additionally checks if the child account has already been linked before transferring the NFT, so you’ll see that this transaction is used in the Blockchain-native flow for withdrawals as well.
    
    * `multisig_add_as_child_and_nft_transfer`
        * `nftID: UInt64`
    
    ```bash
    flow transactions build transactions/child_account/multisig_add_as_child_and_nft_transfer.cdc <NFT_ID> --proposer parent --payer parent --authorizer parent --authorizer child --filter payload --save multisig_add_as_child_and_nft_transfer
    ```
    
    ```bash
    flow transactions sign multisig_add_as_child --signer parent --signer child --filter payload --save multisig_add_as_child_and_nft_transfer
    ```
    
    ```bash
    flow transactions send-signed multisig_add_as_child_and_nft_transfer
    ```



### Blockchain-Native Onboarding
<aside>
🔔 Reminder to fulfill pre-requisites from above
</aside>

#### Onboarding

1. Generate public/private key pair
    
    ```sh
    flow keys generate
    ```
    
2. Initialize blockchain-native onboarding
    * `onboarding/blockchain_native_onboarding`
        1. `pubKey: String`
        2. `fundingAmt: UFix64`
        3. `childAccountName: String`
        4. `childAccountDescription: String`
        5. `clientIconURL: String`
        6. `clientExternalURL: String`
        7. `minterAddress: Address`
        
        <aside>
        ⚠️ Note: If you’re using `flow-cli`, you’ll want to add the created account as `“child”` to your `flow.json` before continuing. This is similar to the same step in walletless onboarding above
        </aside>
        
3. Query for new account address from public key 
    * `child_account/get_child_address_from_public_key_on_creator: Address`
        1. `creatorAddress: Address`
        2. `pubKey: String`
    
    ```sh
    flow scripts execute scripts/child_account/get_child_address_from_public_key_on_creator.cdc 01cf0e2f2f715450 <PUBLIC_KEY>
    ```
    

#### Minting TicketToken

Based on Match results (queried by in [7](https://www.notion.so/RPSGame-Onboarding-Walkthrough-201b7ae989704d6dbddb789028395e13) & [8](https://www.notion.so/RPSGame-Onboarding-Walkthrough-201b7ae989704d6dbddb789028395e13) above and checked against the [GamePlayer.id](http://GamePlayer.id) queried in [2](https://www.notion.so/RPSGame-Onboarding-Walkthrough-201b7ae989704d6dbddb789028395e13)), we’ll want to mint tokens to the child account’s `TicketToken.Vault`. These tokens can be redeemed for an `ArcadePrize.NFT` later in the demo.

1. Mint tokens to the player’s app account
    * `ticket_token/mint_tokens`
        1. `recipient: Address`
        2. `amount: UFix64`
        
        ```sh
        flow transactions send transactions/ticket_token/mint_tokens.cdc 179b6b1cb6755e31 <AMOUNT> --signer game-dev
        ```
        
2. Query the balance of tokens in the account
    * `ticket_token/get_balance: UFix64` - panics if Vault is not configured
        * `of: Address`
    
    ```sh
    flow scripts execute scripts/ticket_token/get_balance.cdc 179b6b1cb6755e31
    ```
    

#### Minting ArcadePrize.NFT

In this section, we’ll use the TicketToken.Vault in the child account to pay for an NFT to the signing account’s Collection. This serves as an example for how a dApp can present and utilize the assets in a connected account’s child account(s), creating a seamless experience compared to the fragmented UX previously inherent to isolated app accounts.

1. Query for the TicketToken.Vault.balance in each of the user’s child accounts
    1. `ticket_token/get_all_account_balances_from_storage: {Address: UFix64}`
        * `parentAddress: Address`
    
        ```sh
        flow scripts execute scripts/ticket_token/get_balance_of_all_child_accounts.cdc <PARENT_ADDRESS>
        ```
    
    1. `child_account/get_all_account_balances_from_storage: {Type: VaultInfo}`
        * `address: Address`
        
        ```sh
        fse scripts/child_account/get_all_account_balances_from_storage.cdc <PARENT_ADDRESS>
        ```
        
        ```jsx
        // Where VaultInfo has the following interface
        pub struct VaultInfo {
            pub let name: String?
            pub let symbol: String?
            pub var balance: UFix64
            pub let description: String?
            pub let externalURL: String?
            pub let logos: MetadataViews.Medias?
            pub let storagePathIdentifier: String
            pub let receiverPathIdentifier: String?
            pub let providerPathIdentifier: String?
        
            pub fun addBalance(_ addition: UFix64)
        }
        ```
    
2. Query for all publicly accessible NFTs in the connected account & its child accounts
    * `child_account/get_all_nft_display_views_from_public: [NFTData]`
        * `address: Address`

    ```bash
    flow scripts execute scripts/child_account/get_all_nft_display_views_from_public.cdc <PARENT_ADDRESS>
    ```

    ```jsx
    // Where NFTData has the following interface
    pub struct NFTData {
        pub let name: String
        pub let description: String
        pub let thumbnail: String
        pub let resourceID: UInt64
        pub let ownerAddress: Address?
        pub let collectionName: String
        pub let collectionDescription: String
        pub let collectionURL: String
        pub let collectionStoragePathIdentifier: String?
        pub let collectionPublicPathIdentifier: String
    }
    ```

1. Mint a rainbow duck for 10.0 TicketTokens, redeeming the TicketTokens in the user’s child account & minting to the signer’s Collection
    * `arcade_prize/mint_rainbow_duck_paying_with_child_vault`
        1. `fundingChildAddress: Address`
        2. `minterAddress: Address`
    
    ```sh
    flow transactions send transactions/arcade_prize/mint_rainbow_duck_paying_with_child_vault.cdc 179b6b1cb6755e31 01cf0e2f2f715450 --signer parent
    ```
    
1. Again query for all publicly accessible NFTs in the connected account & its child accounts to see the NFT that was minted among all of the user’s owned NFTs
    * `child_account/get_all_nft_display_views_from_public: [NFTData]`
        * `address: Address`
    
    ```bash
    flow scripts execute scripts/child_account/get_all_nft_display_views_from_public.cdc <PARENT_ADDRESS>
    ```
___

### Playing Self-Custodied on Testnet

The contracts will be deployed the week of February 13th, and this README will be updated with all contract addresses once that occurs. The following instructions are just reference until then.

If you want to play this game on testnet in a fully fledged Hybrid Custody dApp, check out our demo implementation [here](https://github.com/onflow/walletless-arcade-example). <- To be updated once live on testnet.

As for good old fashioned self-custody, while you won't be able to perform TicketToken minting, you can play RockPaperScissors Matches using your own wallet and NFTs. You could however use your own NFTs to engage with the contracts via Flow CLI, [FlowRunner](https://runflow.pratikpatel.io/) or [Raft](https://raft.page/nvdtf/welcome-to-raft). Here's how:

1. Mint a [MonsterMaker NFT](https://monster-maker-web-client.vercel.app/)
    1. Connect your wallet
    1. Initialize your account
    1. Choose your monster configuration
    1. Mint!
    1. View in app. Alternatively, you can check out your account in [FlowView](https://testnet.flowview.app/)
1. Once you have your NFT, you need to setup your account's GamePlayer resource
    * `/rock_paper_scissors_game/game_player/setup_game_player.cdc`
1. After you have an NFT & GamePlayer configured, you're ready to play the game!
    * `/rock_paper_scissors_game/game_player/setup_new_singleplayer_match.cdc`
        1. `submittingNFTID: UInt64`
        1. `matchTimeLimitInMinutes: UInt`
1. Submit your move & the randomized second player's move
    * `/rock_paper_scissors_game/game_player/submit_both_singleplayer_moves.cdc`
        1. `matchID: UInt64`
        1. `move: UInt8`
1. Resolve the Match & return your NFT. Note that resolution needs to occur at least one block from when the last move was submitted.
    * `/rock_paper_scissors_game/game_player/resolve_match_and_return_nfts.cdc`
        * `matchID: UInt64`
1. Query the moves played for the Match
    * `rock_paper_scissors_game/get_match_move_history: {UInt64: RockPaperScissorsGame.SubmittedMove}?`
        * `matchID: UInt64`
1. You can additionally query your NFT's win/loss record
    * `game_piece_nft/get_rps_win_loss: GamingMetadataViews.BasicWinLoss?`
        1. `address: Address`
        2. `id: UInt64`

And you just used a MonsterMaker NFT to play singleplayer Rock Paper Scissors on-chain!