import RockPaperScissorsGame from "../../contracts/RockPaperScissorsGame.cdc"

/// Transaction a player might use to cheat a match on resolution
/// by conditioning match resolution on the signer winning
///
transaction(matchID: UInt64) {
    
    let gamePlayerRef: &RockPaperScissorsGame.GamePlayer
    let matchPlayerActionsRef: &{RockPaperScissorsGame.MatchPlayerActions}

    prepare(acct: AuthAccount) {
        // Get the GamePlayer reference from the signing account's storage
        self.gamePlayerRef = acct
            .borrow<&RockPaperScissorsGame.GamePlayer>(
                from: RockPaperScissorsGame.GamePlayerStoragePath
            ) ?? panic("Could not borrow GamePlayer reference!")
        // Get a reference to the relevant MatchPlayerActions Capability
        let matchPlayerActionsCap: Capability<&{RockPaperScissorsGame.MatchPlayerActions}> = self.gamePlayerRef
            .getMatchPlayerCaps()[matchID]
            ?? panic("Could not retrieve MatchPlayer capability for given matchID!")
        self.matchPlayerActionsRef = matchPlayerActionsCap
            .borrow()
            ?? panic("Could not borrow Reference to MatchPlayerActions Capability!")
    }

    execute {
        // Resolve the Match
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
 