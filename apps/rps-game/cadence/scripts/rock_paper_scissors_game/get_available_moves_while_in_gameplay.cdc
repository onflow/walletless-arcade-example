import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import GamePieceNFT from "../../contracts/GamePieceNFT.cdc"
import RockPaperScissorsGame from "../../contracts/RockPaperScissorsGame.cdc"

/// Returns an array with the moves available for a GamePlayer in the given Match.id
pub fun main(playerAddr: Address, matchID: UInt64): [RockPaperScissorsGame.Moves]? {

    let playerAcct = getAccount(playerAddr)
    
    // Get the GamePlayer reference from the player account's storage
    let gamePlayerCap = playerAcct
        .getCapability<&{
            RockPaperScissorsGame.GamePlayerPublic
        }>(
            RockPaperScissorsGame.GamePlayerPublicPath
        )
    let gamePlayerRef = gamePlayerCap
        .borrow()
        ?? panic("Could not borrow reference to GamePlayerPublic at address ".concat(playerAddr.toString()))

    // Return the player's available moves for the given Match
    return gamePlayerRef.getAvailableMoves(matchID: matchID)
}
