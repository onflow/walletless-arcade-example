import "NonFungibleToken"
import "GamePieceNFT"
import "MetadataViews"

/// Configures signer's account with a GamePieceNFT Collection
///
transaction {
    prepare(signer: AuthAccount) {
        // if the account doesn't already have a collection
        if signer.borrow<&GamePieceNFT.Collection>(from: GamePieceNFT.CollectionStoragePath) == nil {
            // create & save it to the account
            signer.save(<-GamePieceNFT.createEmptyCollection(), to: GamePieceNFT.CollectionStoragePath)
        }
        if !signer.getCapability<
                &GamePieceNFT.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, GamePieceNFT.GamePieceNFTCollectionPublic, MetadataViews.ResolverCollection}
            >(GamePieceNFT.CollectionPublicPath).check() {
            signer.unlink(GamePieceNFT.CollectionPublicPath)
            // create a public capability for the collection
            signer.link<&GamePieceNFT.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, GamePieceNFT.GamePieceNFTCollectionPublic, MetadataViews.ResolverCollection}>(GamePieceNFT.CollectionPublicPath, target: GamePieceNFT.CollectionStoragePath)
        }
        if !signer.getCapability<&GamePieceNFT.Collection{NonFungibleToken.Provider}>(
                GamePieceNFT.ProviderPrivatePath
            ).check() {
            signer.unlink(GamePieceNFT.ProviderPrivatePath)
            // create a private capability for the collection
            signer.link<&GamePieceNFT.Collection{NonFungibleToken.Provider}>(GamePieceNFT.ProviderPrivatePath, target: GamePieceNFT.CollectionStoragePath)
        }
    }
}
