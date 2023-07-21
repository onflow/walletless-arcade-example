import "NonFungibleToken"
import "MetadataViews"

import "ArcadePrize"

/// Validates correct configuration of GamePieceNFT resource & Capabilities
///
pub fun main(address: Address): Bool {
    
    let public = getAccount(address).getCapability<&ArcadePrize.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, ArcadePrize.GamePieceNFTCollectionPublic, MetadataViews.ResolverCollection}>(
            ArcadePrize.CollectionPublicPath
        )
    let private = getAuthAccount(address).getCapability<&ArcadePrize.Collection{NonFungibleToken.Provider}>(
            ArcadePrize.ProviderPrivatePath
        )

    return public.check() && private.check()
}