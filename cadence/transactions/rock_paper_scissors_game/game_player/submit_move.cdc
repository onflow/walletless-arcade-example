import RockPaperScissorsGame from "../../../contracts/RockPaperScissorsGame.cdc"

/// Transaction to submit player's move
/// int moves: 0 rock, 1 paper, 2 scissors
///
transaction(matchID: UInt64, move: UInt8) {
    
    let gamePlayerRef: &RockPaperScissorsGame.GamePlayer
    let moveAsEnum: RockPaperScissorsGame.Moves

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
    }

    execute {
        // Submit moves for the game
        self.gamePlayerRef.submitMoveToMatch(matchID: matchID, move: self.moveAsEnum)
    }
}
 