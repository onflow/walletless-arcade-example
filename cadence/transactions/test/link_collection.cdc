import "NonFungibleToken"
import "MetadataViews"
import "GamePieceNFT"

/// Transaction to relink GamePieceNFT collection in the signer's account
///
transaction {

    prepare(acct: AuthAccount) {
        // Return early if the account already has a collection
        if acct.borrow<&GamePieceNFT.Collection>(from: GamePieceNFT.CollectionStoragePath) == nil {
            return
        }

        // create a public capability for the collection assuming a
        // Collection is already saved at GamePieceNFT.CollectionStoragePath
        acct.link<&{
            NonFungibleToken.Receiver,
            NonFungibleToken.CollectionPublic,
            GamePieceNFT.GamePieceNFTCollectionPublic,
            MetadataViews.ResolverCollection
        }>(
            GamePieceNFT.CollectionPublicPath,
            target: GamePieceNFT.CollectionStoragePath
        )
    }
}
