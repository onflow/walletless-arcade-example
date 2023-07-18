import "RockPaperScissorsGame"
import "GamingMetadataViews"

/// Returns RockPaperScissorsGame metadata stored as GamingMetadataViews.GameContractMetadata
///
pub fun main(): GamingMetadataViews.GameContractMetadata {
    return RockPaperScissorsGame.info
}