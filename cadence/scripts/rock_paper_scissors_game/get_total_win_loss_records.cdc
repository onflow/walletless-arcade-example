import GamingMetadataViews from "../../contracts/GamingMetadataViews.cdc"
import RockPaperScissorsGame from "../../contracts/RockPaperScissorsGame.cdc"

/// This script returns the winLossRecords stored in RockPaperScissors contract
///
pub fun main(): {UInt64: GamingMetadataViews.BasicWinLoss} {
    return RockPaperScissorsGame.getTotalWinLossRecords()
}