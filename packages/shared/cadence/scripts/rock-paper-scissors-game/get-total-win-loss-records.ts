const GET_TOTAL_WIN_LOSS_RECORDS = `
import GamingMetadataViews from 0xGamingMetadataViews
import RockPaperScissorsGame from 0xRockPaperScissorsGame

/// This script returns the winLossRecords stored in RockPaperScissors contract
///
pub fun main(): {UInt64: GamingMetadataViews.BasicWinLoss} {
    return RockPaperScissorsGame.getTotalWinLossRecords()
}
`

export default GET_TOTAL_WIN_LOSS_RECORDS
