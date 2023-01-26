import RockPaperScissorsGame from "../../contracts/RockPaperScissorsGame.cdc"

transaction(matchID: UInt64) {
    execute {
        RockPaperScissorsGame.submitAutomatedPlayerMove(matchID: matchID)
    }
}
