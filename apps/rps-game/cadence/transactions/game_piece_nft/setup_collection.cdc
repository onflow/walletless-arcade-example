import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import MetadataViews from "../../contracts/utility/MetadataViews.cdc"
import GamePieceNFT from "../../contracts/GamePieceNFT.cdc"

/// Transaction to setup GamePieceNFT collection in the signer's account
transaction {

    prepare(acct: AuthAccount) {
        // Return early if the account already has a collection
        if acct.borrow<&GamePieceNFT.Collection>(from: GamePieceNFT.CollectionStoragePath) != nil {
            return
        }

        // Create a new empty collection
        let collection <- GamePieceNFT.createEmptyCollection()

        // save it to the account
        acct.save(<-collection, to: GamePieceNFT.CollectionStoragePath)

        // create a public capability for the collection
        acct.link<&{
            NonFungibleToken.Receiver,
            NonFungibleToken.CollectionPublic,
            GamePieceNFT.GamePieceNFTCollectionPublic,
            MetadataViews.ResolverCollection
        }>(
            GamePieceNFT.CollectionPublicPath,
            target: GamePieceNFT.CollectionStoragePath
        )

        // Link the Provider Capability in private storage
        acct.link<&{
            NonFungibleToken.Provider
        }>(
            GamePieceNFT.ProviderPrivatePath,
            target: GamePieceNFT.CollectionStoragePath
        )
    }
}
