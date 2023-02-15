import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import GamePieceNFT from "../../contracts/GamePieceNFT.cdc"
import MetadataViews from "../../contracts/utility/MetadataViews.cdc"
import FungibleToken from "../../contracts/utility/FungibleToken.cdc"

/// This transction uses the MinterPublic resource to mint a new NFT
///
transaction(
    background: Int,
    head: Int,
    torso: Int,
    leg: Int,
    recipient: Address
) {

    // local variable for storing the minter reference
    let minterRef: &GamePieceNFT.Minter
    /// Reference to the receiver's collection
    let recipientCollectionRef: &GamePieceNFT.Collection{NonFungibleToken.CollectionPublic}
    /// NFT ID 
    let receiverCollectionLengthBefore: Int

    prepare(minter: AuthAccount) {

        // Borrow a reference to the Minter in storage
        self.minterRef = minter.borrow<
                &GamePieceNFT.Minter
            >(
                from: GamePieceNFT.MinterStoragePath
            ) ?? panic("Couldn't borrow reference to Minter from Capability")
        // Borrow the recipient's public NFT collection reference
        self.recipientCollectionRef = getAccount(recipient)
            .getCapability(GamePieceNFT.CollectionPublicPath)
            .borrow<&GamePieceNFT.Collection{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not get receiver reference to the NFT Collection")
        // Assign length of collection before minting for use in post-condition
        self.receiverCollectionLengthBefore = self.recipientCollectionRef.getIDs().length

    }

    execute {
        // Build the MonsterComponent struct from given arguments
        let componentValue = GamePieceNFT.MonsterComponent(
                background: background,
                head: head,
                torso: torso,
                leg: leg
            )
        // mint the NFT and deposit it to the recipient's collection
        self.minterRef.mintNFT(
            recipient: self.recipientCollectionRef,
            component: componentValue
        )
    }
    post {
        self.recipientCollectionRef.getIDs().length == self.receiverCollectionLengthBefore + 1:
            "The NFT was not successfully deposited to receiver's collection!"
    }
}
 