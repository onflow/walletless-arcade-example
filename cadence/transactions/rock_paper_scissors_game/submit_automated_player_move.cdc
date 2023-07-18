import "RockPaperScissorsGame"

transaction(matchID: UInt64) {
    execute {
        RockPaperScissorsGame.submitAutomatedPlayerMove(matchID: matchID)
    }
}
