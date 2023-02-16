import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import MetadataViews from "../../contracts/utility/MetadataViews.cdc"
import GamePieceNFT from "../../contracts/GamePieceNFT.cdc"

/// Script to check if GamePieceNFTCollectionPublic is configured at
/// a given address
///
pub fun main(address: Address): Bool {
    return getAccount(address).getCapability<
        &GamePieceNFT.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, GamePieceNFT.GamePieceNFTCollectionPublic, MetadataViews.ResolverCollection}
    >(
        GamePieceNFT.CollectionPublicPath
    ).check()
}
