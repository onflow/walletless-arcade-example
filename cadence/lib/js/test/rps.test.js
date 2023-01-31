import path from "path";
import { 
  emulator, 
  init, 
  getAccountAddress, 
  deployContractByName, 
  sendTransaction, 
  shallPass,
  shallRevert,
  executeScript 
} from "@onflow/flow-js-testing";
import fs from "fs";
import {
  assertCollectionLength,
  assertNFTInCollection
} from "./templates/assertion_templates";
import {
  setupAccountNFTCollection,
  mintNFT,
  accessProviderPasses,
  accessProviderReverts,
  setupGamePlayer,
  accessGamePlayerIDFromPrivatePasses,
  accessGamePlayerIDFromPrivateReverts,
  onboardPlayer,
  setupNewSingleplayerMatch,
  setupNewMultiplayerMatch,
  submitMovePasses,
  submitMoveReverts,
  submitAutomatedPlayerMovePasses,
  submitAutomatedPlayerMoveReverts,
  submitBothSingleplayerMovesPasses,
  submitBothSingleplayerMovesReverts,
  escrowNFTToExistingMatch,
  resolveMatchPasses,
  resolveMatchReverts,
  returnNFTsFromEscrowPasses,
  returnNFTsFromEscrowReverts,
  resolveMatchAndReturnNFTsPasses,
  cheatSingleplayerSubmissionReverts,
  cheatMultiplayerSubmissionReverts,
  blockResolutionReverts,
  removeAllRPSAttachmentsPasses
} from "./templates/transaction_templates";
import {
  getAssignedMovesFromNFT,
  getCollectionIDs, getGamePlayerID, getMatchesInLobby, getMatchesInPlay, getMatchMoveHistory, getRPSWinLoss
} from "./templates/script_templates";

// Auxiliary function for deploying the cadence contracts
async function deployContract(param) {
  const [result, error] = await deployContractByName(param);
  if (error != null) {
    console.log(`Error in deployment - ${error}`);
    emulator.stop();
    process.exit(1);
  }
}

const MATCH_TIME_LIMIT = 10;
const ROCK = 0;
const PAPER = 0;
const SCISSORS = 0;
//const get_collection_ids = fs.readFileSync(path.resolve(__dirname, "./../../../scripts/game_piece_nft/get_collection_ids.cdc"), {encoding:'utf8', flag:'r'});
//const get_matches_in_play = fs.readFileSync(path.resolve(__dirname, "./../../../scripts/rock_paper_scissors_game/get_matches_in_play.cdc"), {encoding:'utf8', flag:'r'});
//const get_match_move_history = fs.readFileSync(path.resolve(__dirname, "./../../../scripts/rock_paper_scissors_game/get_match_move_history.cdc"), {encoding:'utf8', flag:'r'});
//const get_rps_win_loss = fs.readFileSync(path.resolve(__dirname, "./../../../scripts/game_piece_nft/get_rps_win_loss.cdc"), {encoding:'utf8', flag:'r'});

// Defining the test suite for the fungible token switchboard
describe("rockpaperscissorsgame", ()=>{

  // Variables for holding the account address
  let serviceAccount;
  let gameAdmin;
  let playerOne;
  let playerTwo;

  // Before each test...
  beforeEach(async () => {
    // We do some scafolding...

    // Getting the base path of the project
    const basePath = path.resolve(__dirname, "./../../../"); 
		// You can specify different port to parallelize execution of describe blocks
    const port = 8080; 
		// Setting logging flag to true will pipe emulator output to console
    const logging = false;

    await init(basePath);
    await emulator.start({ logging });

    // ...then we deploy the ft and example token contracts using the getAccountAddress function
    // from the flow-js-testing library...

    // Create a service account and deploy contracts to it
    serviceAccount = await getAccountAddress("ServiceAccount")
    gameAdmin = await getAccountAddress("GameAdmin");
    
    await deployContract({ to: serviceAccount, name: "utility/FungibleToken"});
    await deployContract({ to: serviceAccount, name: "utility/NonFungibleToken"});
    await deployContract({ to: serviceAccount, name: "utility/MetadataViews"});
    await deployContract({ to: serviceAccount, name: "GamingMetadataViews"});
    await deployContract({ to: gameAdmin, name: "RockPaperScissorsGame"});

    playerOne = await getAccountAddress("PlayerOne");
    playerTwo = await getAccountAddress("PlayerTwo");

  });

  // After each test we stop the emulator, so it could be restarted
  afterEach(async () => {
    return emulator.stop();
  });

  /************
   * Setup
   ************/

  // First test checks if a user can get a GamePieceNFT
  test("player should be able to mint GamePieceNFT", async () => {
    // First step: create a collection
    await setupAccountNFTCollection(playerOne);
    // Second step: mint NFT
    await mintNFT(playerOne, serviceAccount);
    // Third step: assert collection length
    await assertCollectionLength(playerOne, 1);
  });

  // Second test checks if a player is able to create a GamePlayer & is configured correctly
  test("player should be able to create a GamePlayer", async () => {
    // First step: create, save & link a GamePlayer resource
    await setupGamePlayer(playerOne);
    // Second step: ensure GamePlayerPublic capability is accessible to all
    const gamePlayerID = await getGamePlayerID(playerOne);
    expect(gamePlayerID).not.toBe(null);
    // Third step: ensure GamePlayerID private capability is accessible to signer
    await accessGamePlayerIDFromPrivatePasses(playerOne);
    // Fourth step: ensure GamePlayerID private capabilitiy is not accessible to public
    await accessGamePlayerIDFromPrivateReverts(serviceAccount);
  });

  // Third test checks if single onboarding transaction creates GamePlayer, Collection & NFT
  // and configures them correctly
  test("player should have all resources configured with single onboarding transaction", async () => {
    // First step: create, save & link GamePlayer & Collection resources & mint NFT
    await onboardPlayer(playerOne, serviceAccount);
    // Second step: ensure GamePlayerPublic capability is accessible
    const gamePlayerID = await getGamePlayerID(playerOne);
    expect(gamePlayerID).not.toBe(null);
    // Third step: ensure GamePlayerID private capability is accessible to signer
    await accessGamePlayerIDFromPrivatePasses(playerOne);
    // Fourth step: ensure GamePlayerID private capabilitiy is not accessible to public
    await accessGamePlayerIDFromPrivateReverts(serviceAccount);
    // Fifth step: ensure CollectionPublic capability is accessible to all by checking Collection length
    await assertCollectionLength(playerOne, 1);
    // Sixth step: ensure Provider capability is accessible to signer
    await accessProviderPasses(playerOne);
    // Seventh step: ensure Provider capability is not accessible to all
    await accessProviderReverts(serviceAccount);
  });

  /*****************
   * Singleplayer
   *****************/

  // Fourth test checks if a player is able to create a single player Match, escrowing its GamePieceNFT
  test("player should be able to create a single player Match", async () => {
    // First step: create, save & link GamePlayer & Collection resources & mint NFT
    await onboardPlayer(playerOne, serviceAccount);
    // Second step: get the GamePieceNFT id
    const nftIDs = await getCollectionIDs(playerOne);
    // Third step: create a Match resource for a single player
    await setupNewSingleplayerMatch(playerOne, parseInt(nftIDs[0]), MATCH_TIME_LIMIT);
  });

  // Fifth test checks if a player is able to submit moves to a single player match
  test("player should be able to submit Move to a single player Match", async () => {
    // First step: create, save & link GamePlayer & Collection resources & mint NFT
    await onboardPlayer(playerOne, serviceAccount);
    // Second step: get the GamePieceNFT id
    const nftIDs = await getCollectionIDs(playerOne);
    // Third step: create a Match resource for a single player
    await setupNewSingleplayerMatch(playerOne, parseInt(nftIDs[0]), MATCH_TIME_LIMIT);
    // Fourth step: get the Match id
    const matchIDs = await getMatchesInPlay(playerOne);
    // Fifth step: submit move to match 
    await submitMovePasses(playerOne, parseInt(matchIDs[0]), ROCK);
    // Sixth step: try to submit another move & fail
    await submitMoveReverts(playerOne, parseInt(matchIDs[0]), ROCK);
    // Seventh step: submit automated player's move
    await submitAutomatedPlayerMovePasses(parseInt(matchIDs[0]))
    // Eighth step: try to submit automated player's move again & fail
    await submitAutomatedPlayerMoveReverts(parseInt(matchIDs[0]))
  });

  // Sixth test checks if a player is able to submit autoplayer move to a single player Match
  test("player should be able to submit autoplayer Move to a single player Match", async () => {
    // First step: create, save & link GamePlayer & Collection resources & mint NFT
    await onboardPlayer(playerOne, serviceAccount);
    // Second step: get the GamePieceNFT id
    const nftIDs = await getCollectionIDs(playerOne);
    // Third step: create a Match resource for a single player
    await setupNewSingleplayerMatch(playerOne, parseInt(nftIDs[0]), MATCH_TIME_LIMIT);
    // Fourth step: get the Match id
    const matchIDs = await getMatchesInPlay(playerOne);
    // Fifth step: submit player and autoplayer moves to match 
    await submitBothSingleplayerMovesPasses(playerOne, parseInt(matchIDs[0]), ROCK); // Any decent RPS player will always play rock on the first round
  });
  
  // Eighth test checks if a player is able to submit auto player moves to the match it is playing
  test("player should be able to complete SinglePlayer match", async () => {
    // First step: create, save & link GamePlayer & Collection resources & mint NFT
    await onboardPlayer(playerOne, serviceAccount);
    // Second step: get the GamePieceNFT id
    const nftIDs = await getCollectionIDs(playerOne);
    // Third step: create a Match resource for a single player
    await setupNewSingleplayerMatch(playerOne, parseInt(nftIDs[0]), MATCH_TIME_LIMIT);
    
    // Validate: NFT has been escrowed to Match & is not in player's collection
    let emptyCollectionIDs = await getCollectionIDs(playerOne);
    expect(emptyCollectionIDs).toEqual([]);
    
    // Fourth step: get the Match id
    const matchIDs = await getMatchesInPlay(playerOne);
    
    // Validate: Automated player's move cannot be played first
    await submitAutomatedPlayerMoveReverts(parseInt(matchIDs[0]));
    
    // Seventh step: submit move to match 
    await submitMovePasses(playerOne, parseInt(matchIDs[0]), ROCK);
    // Eighth step: submit autoplayer move
    await submitAutomatedPlayerMovePasses(parseInt(matchIDs[0]));
    
    // Ninth step: resolve match & return NFT
    await resolveMatchAndReturnNFTsPasses(playerOne, parseInt(matchIDs[0]));
    // Validate: Check NFT returned is the NFT that was escrowed
    await assertNFTInCollection(playerOne, nftIDs[0]);
    
    // TODO: Add equals value check - need to navigate ResponseObject to relevant value
    // Validate: get match outcome
    const history = await getMatchMoveHistory(parseInt(matchIDs[0]));
    expect(history).not.toBe(null);
    // Validate: Win/loss record attached & accessible on NFT
    const winLoss = await getRPSWinLoss(playerOne, parseInt(nftIDs[0]));
    expect(winLoss).not.toBe(null);
    // Validate: Check the assigned moves on the NFT
    const assignedMoves = await getAssignedMovesFromNFT(playerOne, parseInt(nftIDs[0]));
    expect(assignedMoves).not.toBe(null);
    // Validate: Removing all game-related attachments passes
    await removeAllRPSAttachmentsPasses(playerOne, parseInt(nftIDs[0]));
  });

  // Check that cheating end-to-end is not possible
  test("player should not be able to condition a transaction on match outcome", async () => {
    // First step: create, save & link GamePlayer & Collection resources & mint NFT
    await onboardPlayer(playerOne, serviceAccount);
    // Second step: get the GamePieceNFT id
    const nftIDs = await getCollectionIDs(playerOne);
    // Third step: create a Match resource for a single player
    await setupNewSingleplayerMatch(playerOne, parseInt(nftIDs[0]), MATCH_TIME_LIMIT);
    // Fourth step: get the Match id
    const matchIDs = await getMatchesInPlay(playerOne);
    // Fifth step: attempt to cheat & fail
    await cheatSingleplayerSubmissionReverts(playerOne, parseInt(nftIDs[0]), ROCK);
  });

  /*****************
   * Multiplayer
   *****************/

  // Seventh test checks if a player is able to join an already existing match
  test("player should be able to join an existing Match", async () => {
    // First step: create, save & link GamePlayer & Collection resources & mint NFT
    await onboardPlayer(playerOne, serviceAccount);
    await onboardPlayer(playerTwo, serviceAccount);
    // Fourth step: get the GamePieceNFT ids
    const playerOneNFTIDs = await getCollectionIDs(playerOne);
    const playerTwoNFTIDs = await getCollectionIDs(playerTwo);
    // Fifth step: create a Match resource for a multi player match
    await setupNewMultiplayerMatch(playerOne, parseInt(playerOneNFTIDs[0]), playerTwo, 10);
    // Sixth step: get the Match id
    const matchIDs = await getMatchesInLobby(playerTwo);
    // Seventh step: signup player 2 to match
    await escrowNFTToExistingMatch(playerTwo, parseInt(matchIDs[0]), parseInt(playerTwoNFTIDs[0]));
  });
  
  // Ninth test checks if a player is able to join an already existing match
  test("Two players should be able to complete a Match", async () => {
    // First step: create, save & link GamePlayer & Collection resources & mint NFT
    await onboardPlayer(playerOne, serviceAccount);
    await onboardPlayer(playerTwo, serviceAccount);
    
    // Second step: get the GamePieceNFT ids
    const playerOneNFTIDs = await getCollectionIDs(playerOne);
    const playerTwoNFTIDs = await getCollectionIDs(playerTwo);
    
    // Validate: win/loss records aren't yet attached to NFT
    let playerOneWinLoss = await getRPSWinLoss(playerOne, parseInt(playerOneNFTIDs[0]));
    let playerTwoWinLoss = await getRPSWinLoss(playerTwo, parseInt(playerTwoNFTIDs[0]));
    expect(playerOneWinLoss).toBe(null);
    expect(playerTwoWinLoss).toBe(null);
    // Validate: assigned moves aren't yet attached to NFT
    let playerOneAssignedMoves = await getAssignedMovesFromNFT(playerOne, parseInt(playerOneNFTIDs[0]));
    let playerTwoAssignedMoves = await getAssignedMovesFromNFT(playerTwo, parseInt(playerTwoNFTIDs[0]));
    expect(playerOneAssignedMoves).toBe(null);
    expect(playerTwoAssignedMoves).toBe(null);
    
    // Third step: create a Match resource for a multi player match
    await setupNewMultiplayerMatch(playerOne, parseInt(playerOneNFTIDs[0]), playerTwo, 10);
    
    // Fourth step: get the Match id
    const playerOneInPlayMatchIDs = await getMatchesInPlay(playerOne);
    let playerTwoInLobbyMatchIDs = await getMatchesInLobby(playerTwo);
    // Validate: playerOne has MatchPlayerActions for same Match playerTwo has MatchLobbyActions
    expect(playerOneInPlayMatchIDs).toEqual(playerTwoInLobbyMatchIDs);
    
    // Fifth step: signup player 2 to match by escrowing their NFT
    await escrowNFTToExistingMatch(playerTwo, parseInt(playerTwoInLobbyMatchIDs[0]), parseInt(playerTwoNFTIDs[0]));
    
    // Validate: playerTwo now has ability to play Match
    const playerTwoInPlayMatchIDs = await getMatchesInPlay(playerTwo);
    expect(playerTwoInPlayMatchIDs).toEqual(playerOneInPlayMatchIDs);
    // Validate: MatchLobbyActions has been removed from playerTwo's GamePlayer
    playerTwoInLobbyMatchIDs = await getMatchesInLobby(playerTwo);
    expect(playerTwoInLobbyMatchIDs).toEqual([]);
    
    // Validate: Someone tries to submit an automated player's move & fails
    await submitAutomatedPlayerMoveReverts(parseInt(playerOneInPlayMatchIDs[0]));

    // Sixth step: Player one submits their move - rock
    await submitMovePasses(playerOne, parseInt(playerOneInPlayMatchIDs[0]), ROCK);
    
    // Validate: playerOne tries to cheat auto move and fails
    await submitAutomatedPlayerMoveReverts(parseInt(playerOneInPlayMatchIDs[0]));
    // Validate: playerOne attempts to resolve match early & fails
    await resolveMatchReverts(playerOne, parseInt(playerOneInPlayMatchIDs[0]));
    // Validate: playerOne attempts to return NFTs before Match is over & fails
    await returnNFTsFromEscrowReverts(playerOne, parseInt(playerOneInPlayMatchIDs[0]));

    // Seventh step: playerTwo submits their move - rock
    await submitMovePasses(playerTwo, parseInt(playerTwoInPlayMatchIDs[0]), ROCK);
    
    // Eight step: Resolve match
    await resolveMatchPasses(playerOne, parseInt(playerOneInPlayMatchIDs[0]));

    // Ninth step: Return NFTs from Match escrow
    await returnNFTsFromEscrowPasses(playerOne, parseInt(playerOneInPlayMatchIDs[0]));

    // Validate: Assert the original NFTs are back in the players' collections
    await assertNFTInCollection(playerOne, playerOneNFTIDs[0]);
    await assertNFTInCollection(playerTwo, playerTwoNFTIDs[0]);

    // Tenth step: get match outcome
    const history = await getMatchMoveHistory(parseInt(playerOneInPlayMatchIDs[0]));
    playerOneWinLoss = await getRPSWinLoss(playerOne, parseInt(playerOneNFTIDs[0]));
    playerTwoWinLoss = await getRPSWinLoss(playerTwo, parseInt(playerTwoNFTIDs[0]));
    // Validate: both player NFTs have win/loss records attached & accessible
    // TODO: Add equals value check - need to navigate ResponseObject to relevant value
    expect(history).not.toBe(null);
    expect(playerOneWinLoss).not.toBe(null);
    expect(playerTwoWinLoss).not.toBe(null);
    // Validate: assigned moves have been attached to NFTs & are accessible
    playerOneAssignedMoves = await getAssignedMovesFromNFT(playerOne, parseInt(playerOneNFTIDs[0]));
    playerTwoAssignedMoves = await getAssignedMovesFromNFT(playerTwo, parseInt(playerTwoNFTIDs[0]));
    expect(playerOneAssignedMoves).not.toBe(null);
    expect(playerTwoAssignedMoves).not.toBe(null);
  });

  // Ninth test checks if a player is able to join an already existing match
  test("Second player tries to condition move submission on winning - fails", async () => {
    // First step: create, save & link GamePlayer & Collection resources & mint NFT
    await onboardPlayer(playerOne, serviceAccount);
    await onboardPlayer(playerTwo, serviceAccount);

    // Second step: get the GamePieceNFT ids
    const playerOneNFTIDs = await getCollectionIDs(playerOne);
    const playerTwoNFTIDs = await getCollectionIDs(playerTwo);

    // Validate: win/loss records aren't yet attached to NFT
    let playerOneWinLoss = await getRPSWinLoss(playerOne, parseInt(playerOneNFTIDs[0]));
    let playerTwoWinLoss = await getRPSWinLoss(playerTwo, parseInt(playerTwoNFTIDs[0]));
    expect(playerOneWinLoss).toBe(null);
    expect(playerTwoWinLoss).toBe(null);
    // Validate: assigned moves aren't yet attached to NFT
    let playerOneAssignedMoves = await getAssignedMovesFromNFT(playerOne, parseInt(playerOneNFTIDs[0]));
    let playerTwoAssignedMoves = await getAssignedMovesFromNFT(playerTwo, parseInt(playerTwoNFTIDs[0]));
    expect(playerOneAssignedMoves).toBe(null);
    expect(playerTwoAssignedMoves).toBe(null);

    // Third step: create a Match resource for a multi player match
    await setupNewMultiplayerMatch(playerOne, parseInt(playerOneNFTIDs[0]), playerTwo, 10);

    // Fourth step: get the Match id
    const playerOneInPlayMatchIDs = await getMatchesInPlay(playerOne);
    let playerTwoInLobbyMatchIDs = await getMatchesInLobby(playerTwo);
    // Validate: playerOne has MatchPlayerActions for same Match playerTwo has MatchLobbyActions
    expect(playerOneInPlayMatchIDs).toEqual(playerTwoInLobbyMatchIDs);

    // Fifth step: signup player 2 to match by escrowing their NFT
    await escrowNFTToExistingMatch(playerTwo, parseInt(playerTwoInLobbyMatchIDs[0]), parseInt(playerTwoNFTIDs[0]));

    // Validate: playerTwo now has ability to play Match
    const playerTwoInPlayMatchIDs = await getMatchesInPlay(playerTwo);
    expect(playerTwoInPlayMatchIDs).toEqual(playerOneInPlayMatchIDs);
    // Validate: MatchLobbyActions has been removed from playerTwo's GamePlayer
    playerTwoInLobbyMatchIDs = await getMatchesInLobby(playerTwo);
    expect(playerTwoInLobbyMatchIDs).toEqual([]);

    // Sixth step: Player one submits their move - rock
    await submitMovePasses(playerOne, parseInt(playerOneInPlayMatchIDs[0]), ROCK);
    
    // Seventh step: Player two attempts to cheat, conditioning their move on their winning
    await cheatMultiplayerSubmissionReverts(playerTwo, parseInt(playerTwoInPlayMatchIDs[0]), PAPER);
  });

  // Ninth test checks if a player is able to join an already existing match
  test("Second player tries to condition resolution on winning & fails, other player completes resolution", async () => {
    // First step: create, save & link GamePlayer & Collection resources & mint NFT
    await onboardPlayer(playerOne, serviceAccount);
    await onboardPlayer(playerTwo, serviceAccount);

    // Second step: get the GamePieceNFT ids
    const playerOneNFTIDs = await getCollectionIDs(playerOne);
    const playerTwoNFTIDs = await getCollectionIDs(playerTwo);

    // Validate: win/loss records aren't yet attached to NFT
    let playerOneWinLoss = await getRPSWinLoss(playerOne, parseInt(playerOneNFTIDs[0]));
    let playerTwoWinLoss = await getRPSWinLoss(playerTwo, parseInt(playerTwoNFTIDs[0]));
    expect(playerOneWinLoss).toBe(null);
    expect(playerTwoWinLoss).toBe(null);
    // Validate: assigned moves aren't yet attached to NFT
    let playerOneAssignedMoves = await getAssignedMovesFromNFT(playerOne, parseInt(playerOneNFTIDs[0]));
    let playerTwoAssignedMoves = await getAssignedMovesFromNFT(playerTwo, parseInt(playerTwoNFTIDs[0]));
    expect(playerOneAssignedMoves).toBe(null);
    expect(playerTwoAssignedMoves).toBe(null);

    // Third step: create a Match resource for a multi player match
    await setupNewMultiplayerMatch(playerOne, parseInt(playerOneNFTIDs[0]), playerTwo, 10);

    // Fourth step: get the Match id
    const playerOneInPlayMatchIDs = await getMatchesInPlay(playerOne);
    let playerTwoInLobbyMatchIDs = await getMatchesInLobby(playerTwo);
    // Validate: playerOne has MatchPlayerActions for same Match playerTwo has MatchLobbyActions
    expect(playerOneInPlayMatchIDs).toEqual(playerTwoInLobbyMatchIDs);

    // Fifth step: signup player 2 to match by escrowing their NFT
    await escrowNFTToExistingMatch(playerTwo, parseInt(playerTwoInLobbyMatchIDs[0]), parseInt(playerTwoNFTIDs[0]));

    // Validate: playerTwo now has ability to play Match
    const playerTwoInPlayMatchIDs = await getMatchesInPlay(playerTwo);
    expect(playerTwoInPlayMatchIDs).toEqual(playerOneInPlayMatchIDs);
    // Validate: MatchLobbyActions has been removed from playerTwo's GamePlayer
    playerTwoInLobbyMatchIDs = await getMatchesInLobby(playerTwo);
    expect(playerTwoInLobbyMatchIDs).toEqual([]);

    // Sixth step: Player one submits their move
    await submitMovePasses(playerOne, parseInt(playerOneInPlayMatchIDs[0]), ROCK);
    // Seventh step: Player two submits their move
    await submitMovePasses(playerTwo, parseInt(playerTwoInPlayMatchIDs[0]), PAPER);

    // Eighth step: Player two attempts to cheat, conditioning resolution on their winning
    await blockResolutionReverts(playerTwo, parseInt(playerTwoInPlayMatchIDs[0]));

    // Ninth step: Player one can resolve the match and return their NFT despite player two's failed attempt to cheat
    // and prevent Match resolution
    await resolveMatchAndReturnNFTsPasses(playerOne, parseInt(playerOneInPlayMatchIDs[0]));

    // Validate: Assert the original NFTs are back in the players' collections
    await assertNFTInCollection(playerOne, playerOneNFTIDs[0]);
    await assertNFTInCollection(playerTwo, playerTwoNFTIDs[0]);

    // Tenth step: get match outcome
    const history = await getMatchMoveHistory(parseInt(playerOneInPlayMatchIDs[0]));
    playerOneWinLoss = await getRPSWinLoss(playerOne, parseInt(playerOneNFTIDs[0]));
    playerTwoWinLoss = await getRPSWinLoss(playerTwo, parseInt(playerTwoNFTIDs[0]));
    // Validate: both player NFTs have win/loss records attached & accessible
    // TODO: Add equals value check - need to navigate ResponseObject to relevant value
    expect(history).not.toBe(null);
    expect(playerOneWinLoss).not.toBe(null);
    expect(playerTwoWinLoss).not.toBe(null);
    // Validate: assigned moves have been attached to NFTs & are accessible
    playerOneAssignedMoves = await getAssignedMovesFromNFT(playerOne, parseInt(playerOneNFTIDs[0]));
    playerTwoAssignedMoves = await getAssignedMovesFromNFT(playerTwo, parseInt(playerTwoNFTIDs[0]));
    expect(playerOneAssignedMoves).not.toBe(null);
    expect(playerTwoAssignedMoves).not.toBe(null);
  });
});
