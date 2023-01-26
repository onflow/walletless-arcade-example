import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import MetadataViews from "../../contracts/utility/MetadataViews.cdc"
import GamePieceNFT from "../../contracts/GamePieceNFT.cdc"

/// Transaction to mint GamePieceNFT.NFT in signer's account
///
transaction(minterAddress: Address) {

    let minterRef: &{GamePieceNFT.MinterPublic}
    let recipientCollectionRef: &{NonFungibleToken.CollectionPublic}

    prepare(signer: AuthAccount) {
        // Get a reference to the MinterPublic Capability
        self.minterRef = getAccount(minterAddress)
            .getCapability<
                &{GamePieceNFT.MinterPublic}
            >(
                GamePieceNFT.MinterPublicPath
            ).borrow()
            ?? panic("Could not get a reference to the MinterPublic Capability at the specified address ".concat(minterAddress.toString()))

        // Setup a Collection if one does not exist at the default path
        if !signer.getCapability<&{NonFungibleToken.CollectionPublic}>(GamePieceNFT.CollectionPublicPath).check() {
            // Create a new empty collection
            let collection <- GamePieceNFT.createEmptyCollection()

            // save it to the account
            signer.save(<-collection, to: GamePieceNFT.CollectionStoragePath)

            // create a public capability for the collection
            signer.link<&{
                NonFungibleToken.Receiver,
                NonFungibleToken.CollectionPublic,
                GamePieceNFT.GamePieceNFTCollectionPublic,
                MetadataViews.ResolverCollection
            }>(
                GamePieceNFT.CollectionPublicPath,
                target: GamePieceNFT.CollectionStoragePath
            )

            // Link the Provider Capability in private storage
            signer.link<&{
                NonFungibleToken.Provider
            }>(
                GamePieceNFT.ProviderPrivatePath,
                target: GamePieceNFT.CollectionStoragePath
            )
        }

        // Get a reference to the signer's Receiver Capability
        self.recipientCollectionRef = signer
            .getCapability(GamePieceNFT.CollectionPublicPath)
            .borrow<&{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not get receiver reference to the NFT Collection")
    }

    execute {
        // Realistically, we could make a minter for game NFTs, but this will do for proof of concept
        self.minterRef.mintNFT(recipient: self.recipientCollectionRef)
    }
}
