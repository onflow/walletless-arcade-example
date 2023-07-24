import "GamingMetadataViews"
import "RockPaperScissorsGame"

/// This script returns the winLossRecords stored in RockPaperScissors contract
///
pub fun main(matchID: UInt64): {UInt64: RockPaperScissorsGame.SubmittedMove}? {
    return RockPaperScissorsGame.getMatchMoveHistory(id: matchID)
}