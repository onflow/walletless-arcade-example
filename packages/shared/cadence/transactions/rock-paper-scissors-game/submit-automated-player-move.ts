const SUBMIT_AUTOMATED_PLAYER_MOVE = `
import RockPaperScissorsGame from 0xRockPaperScissorsGame

transaction(matchID: UInt64) {
    execute {
        RockPaperScissorsGame.submitAutomatedPlayerMove(matchID: matchID)
    }
}

`

export default SUBMIT_AUTOMATED_PLAYER_MOVE
