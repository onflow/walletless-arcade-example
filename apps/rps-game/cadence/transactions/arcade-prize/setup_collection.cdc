import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import MetadataViews from "../../contracts/utility/MetadataViews.cdc"
import ArcadePrize from "../../contracts/ArcadePrize.cdc"

/// Transaction to setup GamePieceNFT collection in the signer's account
transaction {

    prepare(signer: AuthAccount) {

        if signer.borrow<&ArcadePrize.Collection>(from: ArcadePrize.CollectionStoragePath) == nil {
            // create Collection & save it to the account
            signer.save(<-ArcadePrize.createEmptyCollection(), to: ArcadePrize.CollectionStoragePath)
        }

        if !signer.getCapability<&ArcadePrize.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, ArcadePrize.ArcadePrizeCollectionPublic, MetadataViews.ResolverCollection}>(
            ArcadePrize.CollectionPublicPath
        ).check() {
            signer.unlink(ArcadePrize.CollectionPublicPath)
            // create a public capability for the collection
            signer.link<&{
                NonFungibleToken.Receiver,
                NonFungibleToken.CollectionPublic,
                ArcadePrize.ArcadePrizeCollectionPublic,
                MetadataViews.ResolverCollection
            }>(
                ArcadePrize.CollectionPublicPath,
                target: ArcadePrize.CollectionStoragePath
            )
        }

        if !signer.getCapability<&ArcadePrize.Collection{NonFungibleToken.Provider}>(
            ArcadePrize.ProviderPrivatePath
        ).check() {
            signer.unlink(ArcadePrize.ProviderPrivatePath)
            // Link the Provider Capability in private storage
            signer.link<&{
                NonFungibleToken.Provider
            }>(
                ArcadePrize.ProviderPrivatePath,
                target: ArcadePrize.CollectionStoragePath
            )
        }
    }
}
 