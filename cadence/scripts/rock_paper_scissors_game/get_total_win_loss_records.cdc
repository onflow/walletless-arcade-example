import "GamingMetadataViews"
import "RockPaperScissorsGame"

/// This script returns the winLossRecords stored in RockPaperScissors contract
///
pub fun main(): {UInt64: GamingMetadataViews.BasicWinLoss} {
    return RockPaperScissorsGame.getTotalWinLossRecords()
}