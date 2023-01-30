import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import MonsterMaker from "../../contracts/MonsterMaker.cdc"
import MetadataViews from "../../contracts/utility/MetadataViews.cdc"
import FungibleToken from "../../contracts/utility/FungibleToken.cdc"

/// This transction uses the NFTMinter resource to mint a new NFT, doing so without
/// requiring payment to mint
///
transaction(
    background: Int,
    head: Int,
    torso: Int,
    leg: Int,
    recipient: Address
) {

    // local variable for storing the minter reference
    let minterRef: &MonsterMaker.NFTMinter
    /// Reference to the receiver's collection
    let recipientCollectionRef: &{NonFungibleToken.CollectionPublic}
    /// NFT ID 
    let receiverCollectionLengthBefore: Int

    prepare(minter: AuthAccount) {

        // Borrow a reference to the NFTMinter Capability in minter account's storage
        // NOTE: This assumes a Capability is stored, and not the base resource - this would occurr
        // if the signing minter was granted the NFTMinter Capability for a base resource located in
        // another account
        let minterCapRef = minter.borrow<
                &Capability<&MonsterMaker.NFTMinter>
            >(
                from: MonsterMaker.MinterStoragePath
            ) ?? panic("Couldn't borrow reference to NFTMinter Capability in storage at ".concat(MonsterMaker.MinterStoragePath.toString()))
        self.minterRef = minterCapRef.borrow() ?? panic("Couldn't borrow reference to NFTMinter from Capability")
        // Borrow the recipient's public NFT collection reference
        self.recipientCollectionRef = getAccount(recipient)
            .getCapability(MonsterMaker.CollectionPublicPath)
            .borrow<&{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not get receiver reference to the NFT Collection")
        // Assign length of collection before minting for use in post-condition
        self.receiverCollectionLengthBefore = self.recipientCollectionRef.getIDs().length

    }

    execute {
        // Build the MonsterComponent struct from given arguments
        let componentValue = MonsterMaker.MonsterComponent(
                background: background,
                head: head,
                torso: torso,
                leg: leg
            )
        // TODO: Add royalty feature to MM using beneficiaries, cuts, and descriptions. At the moment, we don't provide royalties with KI, so this will be an empty list.
        let royalties: [MetadataViews.Royalty] = []
        // mint the NFT and deposit it to the recipient's collection
        self.minterRef.mintNFT(
            recipient: self.recipientCollectionRef,
            component: componentValue,
            royalties: royalties
        )
    }
    post {
        self.recipientCollectionRef.getIDs().length == self.receiverCollectionLengthBefore + 1:
            "The NFT was not successfully deposited to receiver's collection!"
    }
}