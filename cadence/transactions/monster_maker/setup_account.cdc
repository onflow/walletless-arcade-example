import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import MonsterMaker from "../../contracts/MonsterMaker.cdc"
import MetadataViews from "../../contracts/utility/MetadataViews.cdc"
import FungibleToken from "../../contracts/utility/FungibleToken.cdc"

/// Configures signer's account with a MonsterMaker Collection
///
transaction {
    prepare(signer: AuthAccount) {
        // if the account doesn't already have a collection
        if signer.borrow<&MonsterMaker.Collection>(from: MonsterMaker.CollectionStoragePath) == nil {
            // create & save it to the account
            signer.save(<-MonsterMaker.createEmptyCollection(), to: MonsterMaker.CollectionStoragePath)
        }
        if !signer.getCapability<
                &MonsterMaker.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MonsterMaker.MonsterMakerCollectionPublic, MetadataViews.ResolverCollection}
            >(
                MonsterMaker.CollectionPublicPath
            ).check() {
            signer.unlink(MonsterMaker.CollectionPublicPath)
            // create a public capability for the collection
            signer.link<&MonsterMaker.Collection{NonFungibleToken.CollectionPublic, MonsterMaker.MonsterMakerCollectionPublic, MetadataViews.ResolverCollection}>(MonsterMaker.CollectionPublicPath, target: MonsterMaker.CollectionStoragePath)
        }
        if !signer.getCapability<
                &MonsterMaker.Collection{NonFungibleToken.Provider}
            >(
                MonsterMaker.ProviderPrivatePath
            ).check() {
            signer.unlink(MonsterMaker.ProviderPrivatePath)
            // create a private capability for the collection
            signer.link<&MonsterMaker.Collection{NonFungibleToken.Provider}>(MonsterMaker.CollectionPublicPath, target: MonsterMaker.CollectionStoragePath)
        }
    }
}