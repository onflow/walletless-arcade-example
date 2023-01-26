const GET_MATCH_MOVE_HISTORY = `import GamePieceNFT from 0xGamePieceNFT
import GamingMetadataViews from 0xGamingMetadataViews
import RockPaperScissorsGame from 0xRockPaperScissorsGame

/// This script returns the winLossRecords stored in RockPaperScissors contract
///
pub fun main(matchID: UInt64): {UInt64: RockPaperScissorsGame.SubmittedMove}? {
    return RockPaperScissorsGame.getMatchMoveHistory(id: matchID)
}`;

export default GET_MATCH_MOVE_HISTORY;
