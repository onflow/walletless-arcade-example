const SETUP_ACCOUNTS = `
import NonFungibleToken from 0xNonFungibleToken
import MonsterMaker from 0xMonsterMaker
import MetadataViews from 0xMetadataViews
import FungibleToken from 0xFungibleToken

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
`

export default SETUP_ACCOUNTS
