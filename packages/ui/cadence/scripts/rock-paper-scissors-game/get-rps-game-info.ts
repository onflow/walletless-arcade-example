const GET_RPS_GAME_INFO = `
import RockPaperScissorsGame from 0xRockPaperScissorsGame
import GamingMetadataViews from 0xGamingMetadataViews

/// Returns RockPaperScissorsGame metadata stored as GamingMetadataViews.GameContractMetadata
///
pub fun main(): GamingMetadataViews.GameContractMetadata {
    return RockPaperScissorsGame.info
}
`

export default GET_RPS_GAME_INFO
