import RockPaperScissorsGame from "../../../contracts/RockPaperScissorsGame.cdc"

/// Transaction to resolve a Match & return escrowed NFTs to players
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
        // Call for NFTs to be returned to escrowing players' Receiver
        // Note: Could alternatively call for signing player's NFT to be returned, but this 
        // method will return all escrowed NFTs. In case of issue with this method,
        // retrieveUnclaimedNFT() can be used as a fallback.
        self.matchPlayerActionsRef.returnPlayerNFTs()
    }
}
 