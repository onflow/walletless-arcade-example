const GET_MATCH_MOVE_HISTORY_AS_RAW_VALUES = `
import GamingMetadataViews from 0xGamingMetadataViews
import RockPaperScissorsGame from 0xRockPaperScissorsGame

/// This script returns the winLossRecords stored in RockPaperScissors contract
/// in a simplified format
///
/// RockPaperScissorsGame.Moves are defined as an enum where each move is the
/// following raw value
/// - rock == 0
/// - paper == 1
/// - scissors == 2
///
pub fun main(matchID: UInt64): {UInt64: UInt8}? {
    
    // Get the moves from the match
    if let matchMoves = RockPaperScissorsGame.getMatchMoveHistory(id: matchID) {
        let rawValueMoves: {UInt64: UInt8} = {}
        
        for playerID in matchMoves.keys {
            let moveRawValue = matchMoves[playerID]!.move.rawValue
            rawValueMoves.insert(key: playerID, moveRawValue)
        }

        return rawValueMoves
    }
    return nil
}
`

export default GET_MATCH_MOVE_HISTORY_AS_RAW_VALUES
