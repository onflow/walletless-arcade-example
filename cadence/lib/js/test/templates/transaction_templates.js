import {
    sendTransaction,
    shallPass,
    shallRevert
} from "@onflow/flow-js-testing";

// Sets up each account in passed array with an NFT Collection resource,
// reading the transaction code relative to the passed base path
export async function setupAccountNFTCollection(signer) {
    const [txn, e] = await shallPass(
        sendTransaction("game_piece_nft/setup_collection", [signer], [])
    );
};

// Mints an NFT to nftRecipient, signed by signer,
// reading the transaction code relative to the passed base path
export async function mintNFT(signer, minterAddress) {
    // Mint a token to nftRecipient's collection
    const [mintTxn, e] = await shallPass(
        sendTransaction(
            "game_piece_nft/mint_nft",
            [signer],
            [minterAddress]
        )
    );
};

// Passes if NonFungibleToken.Provider is accessible in signer's account
// at expected PrivatePath
export async function accessProviderPasses(signer) {
    await shallPass(
        sendTransaction(
            "test/access_provider_or_panic",
            [signer],
            []
        )
    );
};

// Expects NonFungibleToken.Provider is not accessible in signer's account
// at expected PrivatePath
export async function accessProviderReverts(signer) {
    await shallRevert(
        sendTransaction(
            "test/access_provider_or_panic",
            [signer],
            []
        )
    );
};

// Sets up a GamePlayer resource in the signer's account
export async function setupGamePlayer(signer) {
    const [onboardingTxn, e] = await shallPass(
        sendTransaction(
            "rock_paper_scissors_game/game_player/setup_game_player",
            [signer],
            []
        )
    );
};

// Passes if RockPaperScissorsGame.GamePlayerID is accessible in signer's account
// at expected PrivatePath
export async function accessGamePlayerIDFromPrivatePasses(signer) {
    await shallPass(
        sendTransaction(
            "test/access_game_player_id_or_panic",
            [signer],
            []
        )
    );
};

// Expects RockPaperScissorsGame.GamePlayerID is not accessible in signer's account
// at expected PrivatePath
export async function accessGamePlayerIDFromPrivateReverts(signer) {
    await shallRevert(
        sendTransaction(
            "test/access_game_player_id_or_panic",
            [signer],
            []
        )
    );
};

// Configures an account with everything they need to play RockPaperScissorsGame
// Matches
export async function onboardPlayer(signer, minterAddress) {
    const [onboardingTxn, e] = await shallPass(
        sendTransaction(
            "onboarding/onboard_player",
            [signer],
            [minterAddress]
        )
    );
};

// Sets up a new singleplayer RockPaperScissorsGame.Match, escrowing the desired NFT & setting
// the time limit as given
export async function setupNewSingleplayerMatch(signer, nftID, matchTimeLimit) {
    await shallPass(
        sendTransaction(
            "rock_paper_scissors_game/game_player/setup_new_singleplayer_match",
            [signer],
            [nftID, matchTimeLimit]
        )
    );
};

// Sets up a new multiplayer RockPaperScissorsGame.Match, escrowing the desired NFT & setting
// the time limit as given
export async function setupNewMultiplayerMatch(signer, nftID, secondPlayerAddress, matchTimeLimit) {
    await shallPass(
        sendTransaction(
            "rock_paper_scissors_game/game_player/setup_new_multiplayer_match",
            [signer],
            [nftID, secondPlayerAddress, matchTimeLimit]
        )
    );
};

// Withdraws the specified NFT from the signer's Collection and escrows it into the specified Match
export async function escrowNFTToExistingMatch(signer, matchID, nftID) {
    await shallPass(
        sendTransaction(
            "rock_paper_scissors_game/game_player/escrow_nft_to_existing_match",
            [signer],
            [matchID, nftID]
        )
    );
};

// Submitting given move to specified Match passes
export async function submitMovePasses(signer, matchID, move) {
    await shallPass(
        sendTransaction(
            "rock_paper_scissors_game/game_player/submit_move",
            [signer],
            [matchID, move]
        )
    );
};

// Submitting given move to specified Match reverts
export async function submitMoveReverts(signer, matchID, move) {
    await shallRevert(
        sendTransaction(
            "rock_paper_scissors_game/game_player/submit_move",
            [signer],
            [matchID, move]
        )
    );
};

// Submitting automated player's move for the specified Match passes
export async function submitAutomatedPlayerMovePasses(matchID) {
    await shallPass(
        sendTransaction(
            "rock_paper_scissors_game/submit_automated_player_move",
            [],
            [matchID]
        )
    );
};

// Submitting automated player's move for the specified Match reverts
export async function submitAutomatedPlayerMoveReverts(matchID) {
    await shallRevert(
        sendTransaction(
            "rock_paper_scissors_game/submit_automated_player_move",
            [],
            [matchID]
        )
    );
};

// Submitting both the user's and automated player's move for a singleplayer Match passes
export async function submitBothSingleplayerMovesPasses(signer, matchID, move) {
    await shallPass(
        sendTransaction(
            "rock_paper_scissors_game/game_player/submit_both_singleplayer_moves",
            [signer],
            [matchID, move]
        )
    );
};

// Submitting both the user's and automated player's move for a singleplayer Match reverts
export async function submitBothSingleplayerMovesReverts(signer, matchID, move) {
    await shallRevert(
        sendTransaction(
            "rock_paper_scissors_game/game_player/submit_both_singleplayer_moves",
            [signer],
            [matchID, move]
        )
    );
};

// Failed attempt to cheat a singleplayer Match by submitting a move, attempting to resolve,
// and return NFTs with a post-condition that the signer is the winner
export async function cheatSingleplayerSubmissionReverts(signer, matchID, move) {
    await shallRevert(
        sendTransaction(
            "test/cheat_singleplayer_submission",
            [signer],
            [matchID, move]
        )
    );
};

// Failed attempt to cheat a multiplayer Match by submitting a move, attempting to resolve,
// and return NFTs with a post-condition that the signer is the winner
export async function cheatMultiplayerSubmissionReverts(signer, matchID, move) {
    await shallRevert(
        sendTransaction(
            "test/cheat_multiplayer_submission",
            [signer],
            [matchID, move]
        )
    );
};

// Resolving the specified match passes
export async function resolveMatchPasses(signer, matchID) {
    await shallPass(
        sendTransaction(
            "rock_paper_scissors_game/game_player/resolve_match",
            [signer],
            [matchID]
        )
    );
};

// Resolving the specified match reverts
export async function resolveMatchReverts(signer, matchID) {
    await shallRevert(
        sendTransaction(
            "rock_paper_scissors_game/game_player/resolve_match",
            [signer],
            [matchID]
        )
    );
};

// Failed attempt to block Match resultion by setting post-condition on signer winning the Match
export async function blockResolutionReverts(signer, matchID) {
    await shallRevert(
        sendTransaction(
            "test/cheat_resolution",
            [signer],
            [matchID]
        )
    );
};

// Resolving Match & returning escrowed NFTs passes
export async function resolveMatchAndReturnNFTsPasses(signer, matchID) {
    await shallPass(
        sendTransaction(
            "rock_paper_scissors_game/game_player/resolve_match_and_return_nfts",
            [signer],
            [matchID]
        )
    );
};

// Resolving Match & returning escrowed NFTs reverts
export async function resolveMatchAndReturnNFTsReverts(signer, matchID) {
    await shallRevert(
        sendTransaction(
            "rock_paper_scissors_game/game_player/resolve_match_and_return_nfts",
            [signer],
            [matchID]
        )
    );
};

// Calling for players' escrowed NFTs to be returned from Match escrow passes
export async function returnNFTsFromEscrowPasses(signer, matchID) {
    await shallPass(
        sendTransaction(
            "rock_paper_scissors_game/game_player/return_nfts_from_escrow",
            [signer],
            [matchID]
        )
    );
};

// Calling for players' escrowed NFTs to be returned from Match escrow reverts
export async function returnNFTsFromEscrowReverts(signer, matchID) {
    await shallRevert(
        sendTransaction(
            "rock_paper_scissors_game/game_player/return_nfts_from_escrow",
            [signer],
            [matchID]
        )
    );
};

// Removes RPSAssignedMoves and RPSWinLossRetriever from the specified NFT successfully
export async function removeAllRPSAttachmentsPasses(signer, fromNFT) {
    await shallRevert(
        sendTransaction(
            "game_piece_nft/remove_all_rps_game_attachments",
            [signer],
            [fromNFT]
        )
    );
};
