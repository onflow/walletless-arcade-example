import "NonFungibleToken"
import "MetadataViews"
import "GamePieceNFT"

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
