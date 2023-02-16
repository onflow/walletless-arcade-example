import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import GamePieceNFT from "../../contracts/GamePieceNFT.cdc"
import MetadataViews from "../../contracts/utility/MetadataViews.cdc"
import FungibleToken from "../../contracts/utility/FungibleToken.cdc"

/// This transction uses the MinterPublic resource to mint a new NFT
///
transaction(minterAddress: Address) {

    // local variable for storing the minter reference
    let minterPublicRef: &GamePieceNFT.Minter{GamePieceNFT.MinterPublic}
    /// Reference to the receiver's collection
    let collectionPublicRef: &GamePieceNFT.Collection{NonFungibleToken.CollectionPublic}
    /// NFT ID 
    let receiverCollectionLengthBefore: Int

    prepare(signer: AuthAccount) {

        // Borrow a reference to the MinterPublic
        self.minterPublicRef = getAccount(minterAddress).getCapability<
                &GamePieceNFT.Minter{GamePieceNFT.MinterPublic}
            >(
                GamePieceNFT.MinterPublicPath
            ).borrow()
            ?? panic("Couldn't borrow reference to MinterPublic at ".concat(address.toString()))
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
            signer.link<
                &GamePieceNFT.Collection{NonFungibleToken.CollectionPublic, GamePieceNFT.GamePieceNFTCollectionPublic, MetadataViews.ResolverCollection}
            >(
                GamePieceNFT.CollectionPublicPath,
                target: GamePieceNFT.CollectionStoragePath
            )
        }
        if !signer.getCapability<
                &GamePieceNFT.Collection{NonFungibleToken.Provider}
            >(GamePieceNFT.ProviderPrivatePath).check() {
            signer.unlink(GamePieceNFT.ProviderPrivatePath)
            // create a private capability for the collection
            signer.link<
                &GamePieceNFT.Collection{NonFungibleToken.Provider}
            >(
                GamePieceNFT.ProviderPrivatePath,
                target: GamePieceNFT.CollectionStoragePath
            )
        }
        // Borrow the recipient's public NFT collection reference
        self.collectionPublicRef = signer.getCapability<
                &GamePieceNFT.Collection{NonFungibleToken.CollectionPublic}
            >(
                GamePieceNFT.CollectionPublicPath
            ).borrow()
            ?? panic("Could not get CollectionPublic reference to the signer's NFT Collection")
        // Assign length of collection before minting for use in post-condition
        self.receiverCollectionLengthBefore = self.collectionPublicRef.getIDs().length

    }

    execute {
        // mint the NFT and deposit it to the recipient's collection
        self.minterPublicRef.mintNFT(
            recipient: self.collectionPublicRef,
            component: GamePieceNFT.getRandomComponent()
        )
    }
    post {
        self.collectionPublicRef.getIDs().length == self.receiverCollectionLengthBefore + 1:
            "The NFT was not successfully deposited to receiver's collection!"
    }
}
 