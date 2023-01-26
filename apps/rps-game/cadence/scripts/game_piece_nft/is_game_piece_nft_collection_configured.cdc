import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import GamePieceNFT from "../../contracts/GamePieceNFT.cdc"

/// Script to check if GamePieceNFTCollectionPublic is configured at
/// a given address
///
pub fun main(address: Address): Bool {
    return getAccount(address).getCapability<&{
        GamePieceNFT.GamePieceNFTCollectionPublic
        }>(
            GamePieceNFT.CollectionPublicPath
        ).check()
}
