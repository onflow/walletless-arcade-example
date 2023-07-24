import "NonFungibleToken"
import "MetadataViews"

import "GamePieceNFT"

/// Validates correct configuration of GamePieceNFT resource & Capabilities
///
pub fun main(address: Address): Bool {
    
    let public = getAccount(address).getCapability<&GamePieceNFT.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, GamePieceNFT.GamePieceNFTCollectionPublic, MetadataViews.ResolverCollection}>(
            GamePieceNFT.CollectionPublicPath
        )
    let private = getAuthAccount(address).getCapability<&GamePieceNFT.Collection{NonFungibleToken.Provider}>(
            GamePieceNFT.ProviderPrivatePath
        )

    return public.check() && private.check()
}