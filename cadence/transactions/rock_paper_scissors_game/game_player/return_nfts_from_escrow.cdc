import "RockPaperScissorsGame"

/// ReturnsNFTs from escrow to their owners' Receiver which
/// is stored in the Match resource itself
transaction(matchID: UInt64) {

    let matchPlayerActionsRef: &{RockPaperScissorsGame.MatchPlayerActions}
    
    prepare(acct: AuthAccount) {
        // Get the MatchPlayer reference from the GamePlayer resource
        let gamePlayerRef = acct
            .borrow<&RockPaperScissorsGame.GamePlayer>(from: RockPaperScissorsGame.GamePlayerStoragePath)
            ?? panic("Could not borrow GamePlayer reference!")
        let matchPlayerActionsCap: Capability<&{RockPaperScissorsGame.MatchPlayerActions}> = gamePlayerRef
            .getMatchPlayerCaps()[matchID]
            ?? panic("Could not retrieve MatchPlayer capability for given matchID!")
        self.matchPlayerActionsRef = matchPlayerActionsCap
            .borrow()
            ?? panic("Could not borrow Reference to MatchPlayerActions Capability!")
    }

    execute {
        // Call for NFTs to be returned to escrowing players' Receiver
        self.matchPlayerActionsRef.returnPlayerNFTs()
    }
}
