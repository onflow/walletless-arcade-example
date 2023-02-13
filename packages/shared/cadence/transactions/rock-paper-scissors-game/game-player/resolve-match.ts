const RESOLVE_MATCH = `
import RockPaperScissorsGame from 0xRockPaperScissorsGame

/// Transaction to resolve a Match & return escrowed NFTs to players
///
transaction(matchID: UInt64) {
    
    let gamePlayerRef: &RockPaperScissorsGame.GamePlayer

    prepare(acct: AuthAccount) {
        // Get the GamePlayer reference from the signing account's storage
        self.gamePlayerRef = acct
            .borrow<&RockPaperScissorsGame.GamePlayer>(
                from: RockPaperScissorsGame.GamePlayerStoragePath
            ) ?? panic("Could not borrow GamePlayer reference!")
    }

    execute {
        // Resolve the Match
        self.gamePlayerRef.resolveMatchByID(matchID)
    }
}
`

export default RESOLVE_MATCH
