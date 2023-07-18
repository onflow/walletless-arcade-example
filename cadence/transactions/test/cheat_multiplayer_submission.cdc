import "RockPaperScissorsGame"

/// Transaction a player might use to cheat a match
/// int moves: 0 rock, 1 paper, 2 scissors
///
transaction(matchID: UInt64, move: UInt8) {
    
    let gamePlayerRef: &RockPaperScissorsGame.GamePlayer
    let moveAsEnum: RockPaperScissorsGame.Moves
    let matchPlayerActionsRef: &{RockPaperScissorsGame.MatchPlayerActions}

    prepare(acct: AuthAccount) {
        // Get the GamePlayer reference from the signing account's storage
        self.gamePlayerRef = acct
            .borrow<&RockPaperScissorsGame.GamePlayer>(
                from: RockPaperScissorsGame.GamePlayerStoragePath
            ) ?? panic("Could not borrow GamePlayer reference!")
        // Construct a legible move from the raw input value
        self.moveAsEnum = RockPaperScissorsGame
            .Moves(
                rawValue: move
            ) ?? panic("Given move does not map to a legal RockPaperScissorsGame.Moves value!")
        // Get a reference to the relevant MatchPlayerActions Capability
        let matchPlayerActionsCap: Capability<&{RockPaperScissorsGame.MatchPlayerActions}> = self.gamePlayerRef
            .getMatchPlayerCaps()[matchID]
            ?? panic("Could not retrieve MatchPlayer capability for given matchID!")
        self.matchPlayerActionsRef = matchPlayerActionsCap
            .borrow()
            ?? panic("Could not borrow Reference to MatchPlayerActions Capability!")
    }

    execute {
        // Submit moves for the game
        self.gamePlayerRef.submitMoveToMatch(matchID: matchID, move: self.moveAsEnum)
        // Resolve the Match - should fail due to block height
        self.gamePlayerRef.resolveMatchByID(matchID)
        // Return player NFTs
        self.matchPlayerActionsRef.returnPlayerNFTs()
    }

    post {
        RockPaperScissorsGame
            .determineRockPaperScissorsWinner(
                moves: RockPaperScissorsGame.getMatchMoveHistory(id: matchID)!
            ) == self.gamePlayerRef.id:
            "Signing game player didn't win!"
    }
}
 