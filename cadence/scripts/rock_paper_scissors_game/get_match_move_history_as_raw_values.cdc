import GamingMetadataViews from "../../contracts/GamingMetadataViews.cdc"
import RockPaperScissorsGame from "../../contracts/RockPaperScissorsGame.cdc"

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