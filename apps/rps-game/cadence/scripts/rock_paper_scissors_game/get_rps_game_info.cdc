import RockPaperScissorsGame from "../../contracts/RockPaperScissorsGame.cdc"
import GamingMetadataViews from "../../contracts/GamingMetadataViews.cdc"

/// Returns RockPaperScissorsGame metadata stored as GamingMetadataViews.GameContractMetadata
///
pub fun main(): GamingMetadataViews.GameContractMetadata {
    return RockPaperScissorsGame.info
}