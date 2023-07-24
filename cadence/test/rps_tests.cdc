import Test

pub var accounts: {String: Test.Account} = {}
pub var blockchain = Test.newEmulatorBlockchain()
pub let fungibleTokenAddress: Address = 0xee82856bf20e2aa6
pub let flowTokenAddress: Address = 0x0ae53cb6e3f42a79

pub let dynamicNFT = "DynamicNFT"
pub let gamingMetadataViews = "GamingMetadataViews"
pub let gamePieceNFT = "GamePieceNFT"
pub let ticketToken = "TicketToken"
pub let rockPaperScissorsGame = "RockPaperScissorsGame"
pub let arcadePrize = "ArcadePrize"

pub let gamePieceNFTPublicIdentifier = "GamePieceNFTCollection"
pub let arcadePrizePublicIdentifier = "ArcadePrizeCollection"

pub let pubKey = "af45946342ac9fcc3f909c6f710d3a0c05be903fead0edf77da0bffa572c7a47bfce69218dc54998cdb86f3996fdbfb360be30854f462783188372861549409f"

pub let matchTimeLimit: UInt = 10
pub let rock: UInt8 = 0
pub let paper: UInt8 = 1
pub let scissors: UInt8 = 2

// --------------- Test cases ---------------

pub fun testMintGamePieceNFT() {
    let receiver = blockchain.createAccount()
    setupNFTCollection(receiver, collection: gamePieceNFT)

    assertCollectionConfigured(receiver.address, collection: gamePieceNFT)

    mintRandomGamePieceNFTPublic(receiver)

    let ids = getCollectionIDs(receiver.address, collection: gamePieceNFT)
    Test.assertEqual(1, ids.length)
}

pub fun testSetupGamePlayer() {
    let player = blockchain.createAccount()
    
    let success = txExecutor("rock_paper_scissors_game/game_player/setup_game_player.cdc", [player], [], nil, nil)
    Test.assertEqual(true, success)
    
    assertGamePlayerConfigured(player.address)

    // Ensure we can query GamePlayer.id
    let playerID = getGamePlayerID(player.address)
}

pub fun testMintTicketToken() {
    let mintAmount = 10.0
    let receiver = blockchain.createAccount()

    // Setup & verify TicketToken Vault configured correctly
    setupTicketTokenVault(receiver)
    assertTicketTokenConfigured(receiver.address)

    let balance = getTicketTokenBalance(receiver.address)
    Test.assertEqual(0.0, balance)

    // Mint 10 TicketTokens
    mintTicketTokens(to: receiver.address, amount: mintAmount)
    let newBalance = getTicketTokenBalance(receiver.address)
    Test.assertEqual(mintAmount, newBalance)
}

pub fun testCompleteSinglePlayerMatch() {
    /* --- Onboard Player --- */
    //
    // Configure player's account with game resources
    // **NOTE:** in the example app, we'd onboard players via walletless onboarding. We're not doing that here because 
    // we can't sign test transactions without a Test.Account object
    let player = blockchain.createAccount()
    selfCustodyOnboarding(player)

    // Ensure all resources & Capabilities configured as expected
    assertCollectionConfigured(player.address, collection: gamePieceNFT)
    assertGamePlayerConfigured(player.address)
    assertTicketTokenConfigured(player.address)

    // Query minted NFT.id
    let nftIDs = getCollectionIDs(player.address, collection: gamePieceNFT)
    Test.assertEqual(1, nftIDs.length)
    let nftID = nftIDs[0]

    // Query GamePlayer.id
    let playerID = getGamePlayerID(player.address)

    /* --- Create Single-Player Match --- */
    //
    // Sign up for match
    setupNewSingleplayerMatch(player, nftID: nftID, matchTimeLimit: matchTimeLimit)

    // Get the ID of the match just created
    let matchIDs = getMatchIDsInPlay(player.address)
    Test.assertEqual(1, matchIDs.length)
    let matchID = matchIDs[0]

    /* --- Play the Match --- */
    //
    submitBothSinglePlayerMoves(player, matchID: matchID, move: rock)
    resolveMatch(player, matchID: matchID)

    /* --- Verify Match Results --- */
    //
    let history = getMatchHistoryAsRawValues(matchID: matchID)
        ?? panic("Should have returned valid history, but got nil!")
    assert(history.containsKey(playerID))
    Test.assertEqual(rock, history[playerID]!)
}

pub fun testCompleteMultiPlayerMatch() {
    
    // **NOTE:** in the example app, we'd onboard players via walletless onboarding. We're not doing that here because 
    // we can't sign test transactions without a Test.Account object
    let playerOne = blockchain.createAccount()
    let playerTwo = blockchain.createAccount()

    selfCustodyOnboarding(playerOne)
    selfCustodyOnboarding(playerTwo)

    // Ensure all resources & Capabilities configured as expected
    assertCollectionConfigured(playerOne.address, collection: gamePieceNFT)
    assertGamePlayerConfigured(playerOne.address)
    assertTicketTokenConfigured(playerOne.address)
    assertCollectionConfigured(playerTwo.address, collection: gamePieceNFT)
    assertGamePlayerConfigured(playerTwo.address)
    assertTicketTokenConfigured(playerTwo.address)

    // Query GamePlayer.ids for each player
    let playerOneID = getGamePlayerID(playerOne.address)
    let playerTwoID = getGamePlayerID(playerTwo.address)
    
    // Query minted NFT.ids
    let playerOneIDs = getCollectionIDs(playerOne.address, collection: gamePieceNFT)
    let playerTwoIDs = getCollectionIDs(playerTwo.address, collection: gamePieceNFT)
    let playerOneNFTID = playerOneIDs[0]
    let playerTwoNFTID = playerTwoIDs[0]

    setupNewMultiplayerMatch(playerOne, nftID: playerOneNFTID, playerTwoAddr: playerTwo.address, matchTimeLimit: matchTimeLimit)

    // Get the ID of the match just created
    let playerOneMatchIDs = getMatchIDsInPlay(playerOne.address)
    Test.assertEqual(1, playerOneMatchIDs.length)
    let playerOneMatchID = playerOneMatchIDs[0]

    // Verify playerTwo has the same matchID in their lobby Capabilities
    let playerTwoMatchLobbyIDs = getMatchIDsInLobby(playerTwo.address)
    Test.assertEqual(1, playerTwoMatchLobbyIDs.length)
    let playerTwoMatchLobbyID = playerTwoMatchLobbyIDs[0]
    Test.assertEqual(playerOneMatchID, playerTwoMatchLobbyID)

    // Player two joins the match, escrowing an NFT
    escrowNFTToExistingMatch(playerTwo, matchID: playerTwoMatchLobbyID, nftID: playerTwoNFTID)

    // Verify player two now has the ability to play the match
    let playerTwoMatchIDs = getMatchIDsInPlay(playerTwo.address)
    Test.assertEqual(1, playerTwoMatchLobbyIDs.length)
    let playerTwoMatchID = playerTwoMatchIDs[0]
    Test.assertEqual(playerTwoMatchLobbyID, playerTwoMatchID)
    Test.assertEqual(playerOneMatchID, playerTwoMatchID)

    // Player submit their moves
    submitMove(playerOne, matchID: playerOneMatchID, move: rock)
    submitMove(playerTwo, matchID: playerTwoMatchID, move: scissors)

    // Resolve the match & return escrowed NFTs
    resolveMatchAndReturnNFTs(playerOne, matchID: playerOneMatchID)

    /* --- Verify Match Results --- */
    //
    let history = getMatchHistoryAsRawValues(matchID: playerOneMatchID)
        ?? panic("Should have returned valid history, but got nil!")
    
    assert(history.containsKey(playerOneID))
    assert(history.containsKey(playerTwoID))
    
    Test.assertEqual(rock, history[playerOneID]!)
    Test.assertEqual(scissors, history[playerTwoID]!)
}

pub fun testCheatingMoveFails() {
    let expectedErrorMessage = "Too soon after move submission to resolve the match!"
    
    let playerOne = blockchain.createAccount()
    let playerTwo = blockchain.createAccount()

    selfCustodyOnboarding(playerOne)
    selfCustodyOnboarding(playerTwo)

    // Query GamePlayer.ids for each player
    let playerOneID = getGamePlayerID(playerOne.address)
    let playerTwoID = getGamePlayerID(playerTwo.address)
    
    // Query minted NFT.ids
    let playerOneIDs = getCollectionIDs(playerOne.address, collection: gamePieceNFT)
    let playerTwoIDs = getCollectionIDs(playerTwo.address, collection: gamePieceNFT)
    let playerOneNFTID = playerOneIDs[0]
    let playerTwoNFTID = playerTwoIDs[0]

    setupNewMultiplayerMatch(playerOne, nftID: playerOneNFTID, playerTwoAddr: playerTwo.address, matchTimeLimit: matchTimeLimit)

    // Get the ID of the match just created
    let playerOneMatchIDs = getMatchIDsInPlay(playerOne.address)
    Test.assertEqual(1, playerOneMatchIDs.length)
    let playerOneMatchID = playerOneMatchIDs[0]

    // Verify playerTwo has the same matchID in their lobby Capabilities
    let playerTwoMatchLobbyIDs = getMatchIDsInLobby(playerTwo.address)
    Test.assertEqual(1, playerTwoMatchLobbyIDs.length)
    let playerTwoMatchLobbyID = playerTwoMatchLobbyIDs[0]

    // Player two joins the match, escrowing an NFT
    escrowNFTToExistingMatch(playerTwo, matchID: playerTwoMatchLobbyID, nftID: playerTwoNFTID)

    // Verify player two now has the ability to play the match
    let playerTwoMatchIDs = getMatchIDsInPlay(playerTwo.address)
    Test.assertEqual(1, playerTwoMatchLobbyIDs.length)
    let playerTwoMatchID = playerTwoMatchIDs[0]

    // First player submits their move, second player attempts to condition their move on winning and fails
    submitMove(playerOne, matchID: playerOneMatchID, move: rock)
    let cheatingFails = txExecutor("test/cheat_multiplayer_submission.cdc", [playerTwo], [playerTwoMatchID, scissors], expectedErrorMessage, ErrorType.TX_PANIC)
    Test.assert(cheatingFails)
}

pub fun testCheatingResolutionFails() {
    let expectedErrorMessage = "Signing game player didn't win!"
    
    let playerOne = blockchain.createAccount()
    let playerTwo = blockchain.createAccount()

    selfCustodyOnboarding(playerOne)
    selfCustodyOnboarding(playerTwo)

    // Query GamePlayer.ids for each player
    let playerOneID = getGamePlayerID(playerOne.address)
    let playerTwoID = getGamePlayerID(playerTwo.address)
    
    // Query minted NFT.ids
    let playerOneIDs = getCollectionIDs(playerOne.address, collection: gamePieceNFT)
    let playerTwoIDs = getCollectionIDs(playerTwo.address, collection: gamePieceNFT)
    let playerOneNFTID = playerOneIDs[0]
    let playerTwoNFTID = playerTwoIDs[0]

    setupNewMultiplayerMatch(playerOne, nftID: playerOneNFTID, playerTwoAddr: playerTwo.address, matchTimeLimit: matchTimeLimit)

    // Get the ID of the match just created
    let playerOneMatchIDs = getMatchIDsInPlay(playerOne.address)
    Test.assertEqual(1, playerOneMatchIDs.length)
    let playerOneMatchID = playerOneMatchIDs[0]

    // Verify playerTwo has the same matchID in their lobby Capabilities
    let playerTwoMatchLobbyIDs = getMatchIDsInLobby(playerTwo.address)
    Test.assertEqual(1, playerTwoMatchLobbyIDs.length)
    let playerTwoMatchLobbyID = playerTwoMatchLobbyIDs[0]

    // Player two joins the match, escrowing an NFT
    escrowNFTToExistingMatch(playerTwo, matchID: playerTwoMatchLobbyID, nftID: playerTwoNFTID)

    // Verify player two now has the ability to play the match
    let playerTwoMatchIDs = getMatchIDsInPlay(playerTwo.address)
    Test.assertEqual(1, playerTwoMatchLobbyIDs.length)
    let playerTwoMatchID = playerTwoMatchIDs[0]

    // Players submit their moves, player one with winning move
    submitMove(playerOne, matchID: playerOneMatchID, move: rock)
    submitMove(playerTwo, matchID: playerTwoMatchID, move: scissors)

    // Player two calls for match resolution, conditioning on them winning the match - post-condition succeeds
    let cheatingSucceeds = txExecutor("test/cheat_resolution.cdc", [playerTwo], [playerTwoMatchID], expectedErrorMessage, ErrorType.TX_PANIC)
    Test.assert(cheatingSucceeds)

    // Other player calls for resolution anyway and wins
    resolveMatch(playerOne, matchID: playerOneMatchID)

    /* --- Verify Match Results --- */
    //
    let history = getMatchHistoryAsRawValues(matchID: playerOneMatchID)
        ?? panic("Should have returned valid history, but got nil!")
    
    assert(history.containsKey(playerOneID))
    assert(history.containsKey(playerTwoID))
    
    Test.assertEqual(rock, history[playerOneID]!)
    Test.assertEqual(scissors, history[playerTwoID]!)
}

// --------------- Transaction wrapper functions ---------------

pub fun transferFlow(amount: UFix64, to: Test.Account) {
    let account = blockchain.serviceAccount()

    let code = loadCode("flow_token/transfer_flow.cdc", "transactions")
    let tx = Test.Transaction(
        code: code,
        authorizers: [account.address],
        signers: [],
        arguments: [to.address, amount]
    )

    // Act
    let result = blockchain.executeTransaction(tx)
    Test.assert(result.status == Test.ResultStatus.succeeded)
}

pub fun walletlessOnboarding(_ acct: Test.Account, fundingAmout: UFix64) {
    txExecutor(
        "onboarding/walletless_onboarding.cdc",
        [acct],
        [pubKey, 0.0, 1, 1, 1, 1],
        nil,
        nil
    )
}

pub fun setupNFTCollection(_ acct: Test.Account, collection: String) {
    var success: Bool = false
    switch collection {
        case gamePieceNFT:
            success = txExecutor("game_piece_nft/setup_account.cdc", [acct], [], nil, nil)
        case arcadePrize:
            success = txExecutor("arcade_prize/setup_collection.cdc", [acct], [], nil, nil)
    }
    Test.assert(success)
}

pub fun setupTicketTokenVault(_ acct: Test.Account) {
    let success = txExecutor("ticket_token/setup_account.cdc", [acct], [], nil, nil)
    Test.assert(success)
}

pub fun mintGamePieceNFT(_ acct: Test.Account) {
    let success = txExecutor("game_piece_nft/mint_nft_random_component_public.cdc", [acct], [accounts[gamePieceNFT]!.address], nil, nil)
    Test.assert(success)
}

pub fun mintRandomGamePieceNFTPublic(_ acct: Test.Account) {
    let success = txExecutor("game_piece_nft/mint_nft_random_component_public.cdc", [acct], [accounts[gamePieceNFT]!.address], nil, nil)
    Test.assert(success)
}

pub fun mintTicketTokens(to: Address, amount: UFix64) {
    let success = txExecutor("ticket_token/mint_tokens.cdc", [accounts[ticketToken]!], [to, amount], nil, nil)
    Test.assert(success)
}

pub fun selfCustodyOnboarding(_ acct: Test.Account) {
    let success = txExecutor(
        "onboarding/self_custody_onboarding.cdc",
        [acct],
        [accounts[gamePieceNFT]!.address],
        nil,
        nil
    )
    Test.assert(success)
}

pub fun setupNewSingleplayerMatch(_ acct: Test.Account, nftID: UInt64, matchTimeLimit: UInt) {
    let success = txExecutor(
        "rock_paper_scissors_game/game_player/setup_new_singleplayer_match.cdc",
        [acct],
        [nftID, matchTimeLimit],
        nil,
        nil
    )
    Test.assert(success)
}

pub fun setupNewMultiplayerMatch(_ acct: Test.Account, nftID: UInt64, playerTwoAddr: Address, matchTimeLimit: UInt) {
    let success = txExecutor(
        "rock_paper_scissors_game/game_player/setup_new_multiplayer_match.cdc",
        [acct],
        [nftID, playerTwoAddr, matchTimeLimit],
        nil,
        nil
    )
    Test.assert(success)
}

pub fun escrowNFTToExistingMatch(_ acct: Test.Account, matchID: UInt64, nftID: UInt64) {
    let success = txExecutor(
        "rock_paper_scissors_game/game_player/escrow_nft_to_existing_match.cdc",
        [acct],
        [matchID, nftID],
        nil,
        nil
    )
    Test.assert(success)
}

pub fun submitBothSinglePlayerMoves(_ acct: Test.Account, matchID: UInt64, move: UInt8) {
    let success = txExecutor(
        "rock_paper_scissors_game/game_player/submit_both_singleplayer_moves.cdc",
        [acct],
        [matchID, move],
        nil,
        nil
    )
    Test.assert(success)
}

pub fun submitMove(_ acct: Test.Account, matchID: UInt64, move: UInt8) {
    let success = txExecutor(
        "rock_paper_scissors_game/game_player/submit_move.cdc",
        [acct],
        [matchID, move],
        nil,
        nil
    )
    Test.assert(success)
}

pub fun resolveMatch(_ acct: Test.Account, matchID: UInt64) {
    let success = txExecutor(
        "rock_paper_scissors_game/game_player/resolve_match.cdc",
        [acct],
        [matchID],
        nil,
        nil
    )
    Test.assert(success)
}

pub fun resolveMatchAndReturnNFTs(_ acct: Test.Account, matchID: UInt64) {
    let success = txExecutor(
        "rock_paper_scissors_game/game_player/resolve_match_and_return_nfts.cdc",
        [acct],
        [matchID],
        nil,
        nil
    )
    Test.assert(success)
}

// ---------------- End Transaction wrapper functions

// ---------------- Begin script wrapper functions

pub fun getTicketTokenBalance(_ addr: Address): UFix64 {
    return scriptExecutor("ticket_token/get_balance.cdc", [addr])! as! UFix64
}

pub fun getGamePlayerID(_ addr: Address): UInt64 {
    return scriptExecutor("rock_paper_scissors_game/get_game_player_id.cdc", [addr])! as! UInt64
}

pub fun getCollectionIDs(_ addr: Address, collection: String): [UInt64] {
    let collectionIDs: [UInt64] = []
    switch collection {
        case gamePieceNFT:
            collectionIDs.appendAll((scriptExecutor("game_piece_nft/get_collection_ids.cdc", [addr])! as! [UInt64]))
        case arcadePrize:
            collectionIDs.appendAll((scriptExecutor("game_piece_nft/get_collection_ids.cdc", [addr])! as! [UInt64]))
    }
    return collectionIDs
}

pub fun getMatchIDsInLobby(_ addr: Address): [UInt64] {
    return scriptExecutor("rock_paper_scissors_game/get_matches_in_lobby.cdc", [addr])! as! [UInt64]
}

pub fun getMatchIDsInPlay(_ addr: Address): [UInt64] {
    return scriptExecutor("rock_paper_scissors_game/get_matches_in_play.cdc", [addr])! as! [UInt64]
}

pub fun getMatchHistoryAsRawValues(matchID: UInt64): {UInt64: UInt8}? {
    return scriptExecutor("rock_paper_scissors_game/get_match_move_history_as_raw_values.cdc", [matchID]) as! {UInt64: UInt8}?
}

pub fun assertGamePlayerConfigured(_ address: Address) {
    let configured = scriptExecutor("test/test_game_player_configuration.cdc", [address]) as! Bool?
        ?? panic("GamePlayer was not configured correctly!")
    Test.assertEqual(true, configured)
}

pub fun assertCollectionConfigured(_ address: Address, collection: String) {
    var path: String = ""
    switch collection {
        case gamePieceNFT:
            path = "test/test_game_piece_nft_configuration.cdc"
        case arcadePrize:
            path = "test/test_arcade_prize_configuration.cdc"
    }
    let configured = scriptExecutor(path, [address]) as! Bool?
        ?? panic("NFT Collection was not configured correctly!")
    Test.assertEqual(true, configured)
}

pub fun assertTicketTokenConfigured(_ address: Address) {
    let configured = scriptExecutor("test/test_ticket_token_configuration.cdc", [address]) as! Bool?
        ?? panic("TicketToken Vault was not configured correctly!")
    Test.assertEqual(true, configured)
}

// ---------------- End script wrapper functions

pub fun getTestAccount(_ name: String): Test.Account {
    if accounts[name] == nil {
        accounts[name] = blockchain.createAccount()
    }

    return accounts[name]!
}

pub fun loadCode(_ fileName: String, _ baseDirectory: String): String {
    return Test.readFile("../".concat(baseDirectory).concat("/").concat(fileName))
}

pub fun scriptExecutor(_ scriptName: String, _ arguments: [AnyStruct]): AnyStruct? {
    let scriptCode = loadCode(scriptName, "scripts")
    let scriptResult = blockchain.executeScript(scriptCode, arguments)
    var failureMessage = ""
    if let failureError = scriptResult.error {
        failureMessage = "Failed to execute the script because -:  ".concat(failureError.message)
    }

    assert(scriptResult.status == Test.ResultStatus.succeeded, message: failureMessage)
    return scriptResult.returnValue
}

pub fun expectScriptFailure(_ scriptName: String, _ arguments: [AnyStruct]): String {
    let scriptCode = loadCode(scriptName, "scripts")
    let scriptResult = blockchain.executeScript(scriptCode, arguments)

    assert(scriptResult.error != nil, message: "script error was expected but there is no error message")
    return scriptResult.error!.message
}

pub fun txExecutor(_ filePath: String, _ signers: [Test.Account], _ arguments: [AnyStruct], _ expectedError: String?, _ expectedErrorType: ErrorType?): Bool {
    let txCode = loadCode(filePath, "transactions")

    let authorizers: [Address] = []
    for s in signers {
        authorizers.append(s.address)
    }

    let tx = Test.Transaction(
        code: txCode,
        authorizers: authorizers,
        signers: signers,
        arguments: arguments,
    )

    let txResult = blockchain.executeTransaction(tx)
    if let err = txResult.error {
        if let expectedErrorMessage = expectedError {
            let ptr = getErrorMessagePointer(errorType: expectedErrorType!)
            let errMessage = err.message
            let hasEmittedCorrectMessage = contains(errMessage, expectedErrorMessage)
            let failureMessage = "Expecting - "
                .concat(expectedErrorMessage)
                .concat("\n")
                .concat("But received - ")
                .concat(err.message)
            assert(hasEmittedCorrectMessage, message: failureMessage)
            return true
        }
        panic(err.message)
    } else {
        if let expectedErrorMessage = expectedError {
            panic("Expecting error - ".concat(expectedErrorMessage).concat(". While no error triggered"))
        }
    }

    return txResult.status == Test.ResultStatus.succeeded
}

pub fun setup() {

    // standard contracts
    let nonFungibleToken = blockchain.createAccount()
    let metadataViews = blockchain.createAccount()
    let fungibleTokenMetadataViews = blockchain.createAccount()
    let viewResolver = blockchain.createAccount()
    
    // main contracts
    let accountCreator = blockchain.createAccount()
    let gamingMetadataViews: Test.Account = blockchain.createAccount()
    let dynamicNFT: Test.Account = blockchain.createAccount()
    let gamePieceNFT = blockchain.createAccount()
    let ticketToken = blockchain.createAccount()
    let rockPaperScissorsGame = blockchain.createAccount()
    let arcadePrize = blockchain.createAccount()

    accounts = {
        "NonFungibleToken": nonFungibleToken,
        "MetadataViews": metadataViews,
        "FungibleTokenMetadataViews": fungibleTokenMetadataViews,
        "ViewResolver": viewResolver,
        "AccountCreator": accountCreator,
        "GamingMetadataViews": gamingMetadataViews,
        "DynamicNFT": dynamicNFT,
        "GamePieceNFT": gamePieceNFT,
        "TicketToken": ticketToken,
        "RockPaperScissorsGame": rockPaperScissorsGame,
        "ArcadePrize": arcadePrize
    }

    blockchain.useConfiguration(Test.Configuration({
        "FungibleToken": fungibleTokenAddress,
        "NonFungibleToken": accounts["NonFungibleToken"]!.address,
        "FlowToken": flowTokenAddress,
        "FungibleTokenMetadataViews": accounts["FungibleTokenMetadataViews"]!.address,
        "MetadataViews": accounts["MetadataViews"]!.address,
        "ViewResolver": accounts["ViewResolver"]!.address,
        "AccountCreator": accounts["AccountCreator"]!.address,
        "GamingMetadataViews": accounts["GamingMetadataViews"]!.address,
        "DynamicNFT": accounts["DynamicNFT"]!.address,
        "GamePieceNFT": accounts["GamePieceNFT"]!.address,
        "TicketToken": accounts["TicketToken"]!.address,
        "RockPaperScissorsGame": accounts["RockPaperScissorsGame"]!.address,
        "ArcadePrize": accounts["ArcadePrize"]!.address
    }))

    // deploy standard libs first
    deploy("NonFungibleToken", accounts["NonFungibleToken"]!, "../contracts/utility/NonFungibleToken.cdc")
    deploy("MetadataViews", accounts["MetadataViews"]!, "../contracts/utility/MetadataViews.cdc")
    deploy("FungibleTokenMetadataViews", accounts["FungibleTokenMetadataViews"]!, "../contracts/utility/FungibleTokenMetadataViews.cdc")
    deploy("ViewResolver", accounts["ViewResolver"]!, "../contracts/utility/ViewResolver.cdc")

    // main contracts we'll be testing
    deploy("AccountCreator", accounts["AccountCreator"]!, "../contracts/utility/AccountCreator.cdc")
    deploy("GamingMetadataViews", accounts["GamingMetadataViews"]!, "../contracts/GamingMetadataViews.cdc")
    deploy("DynamicNFT", accounts["DynamicNFT"]!, "../contracts/DynamicNFT.cdc")
    deploy("GamePieceNFT", accounts["GamePieceNFT"]!, "../contracts/GamePieceNFT.cdc")
    deploy("TicketToken", accounts["TicketToken"]!, "../contracts/TicketToken.cdc")
    deploy("RockPaperScissorsGame", accounts["RockPaperScissorsGame"]!, "../contracts/RockPaperScissorsGame.cdc")
    deploy("ArcadePrize", accounts["ArcadePrize"]!, "../contracts/ArcadePrize.cdc")
}

// BEGIN SECTION: Helper functions. All of the following were taken from
// https://github.com/onflow/Offers/blob/fd380659f0836e5ce401aa99a2975166b2da5cb0/lib/cadence/test/Offers.cdc
// - deploy
// - scriptExecutor
// - txExecutor
// - getErrorMessagePointer

pub fun deploy(_ contractName: String, _ account: Test.Account, _ path: String) {
 let contractCode = Test.readFile(path)
    let err = blockchain.deployContract(
        name: contractName,
        code: contractCode,
        account: account,
        arguments: [],
    )

    if err != nil {
        panic(err!.message)
    }
}

pub enum ErrorType: UInt8 {
    pub case TX_PANIC
    pub case TX_ASSERT
    pub case TX_PRE
}

pub fun getErrorMessagePointer(errorType: ErrorType) : Int {
    switch errorType {
        case ErrorType.TX_PANIC: return 159
        case ErrorType.TX_ASSERT: return 170
        case ErrorType.TX_PRE: return 174
        default: panic("Invalid error type")
    }

    return 0
}

// END SECTION: Helper functions
 

 // Copied functions from flow-utils so we can assert on error conditions
 // https://github.com/green-goo-dao/flow-utils/blob/main/cadence/contracts/StringUtils.cdc
pub fun contains(_ s: String, _ substr: String): Bool {
    if let index =  index(s, substr, 0) {
        return true
    }
    return false
}

 // https://github.com/green-goo-dao/flow-utils/blob/main/cadence/contracts/StringUtils.cdc
pub fun index(_ s : String, _ substr : String, _ startIndex: Int): Int?{
    for i in range(startIndex,s.length-substr.length+1){
        if s[i]==substr[0] && s.slice(from:i, upTo:i+substr.length) == substr{
            return i
        }
    }
    return nil
}

// https://github.com/green-goo-dao/flow-utils/blob/main/cadence/contracts/ArrayUtils.cdc
pub fun rangeFunc(_ start: Int, _ end: Int, _ f : ((Int):Void) ) {
    var current = start
    while current < end{
        f(current)
        current = current + 1
    }
}

pub fun range(_ start: Int, _ end: Int): [Int]{
    var res:[Int] = []
    rangeFunc(start, end, fun (i:Int){
        res.append(i)
    })
    return res
}
