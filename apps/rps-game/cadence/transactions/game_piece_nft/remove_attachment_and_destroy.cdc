import GamePieceNFT from "../../contracts/GamePieceNFT.cdc"

/// Transaction that removes the attachment of the specified Type
/// from the NFT with the given id contained in the signer's
/// GamePieceNFT.Collection
///
transaction(fromNFT: UInt64, attachmentType: Type) {
    prepare(signer: AuthAccount) {
        // Get a reference to the signer's GamePieceNFT.Collection
        let collectionRef = signer
            .borrow<&
                GamePieceNFT.Collection
            >(
                from: GamePieceNFT.CollectionStoragePath
            ) ?? panic("Could now borrow reference to user's collection")
        // Remove & destroy the attachment
        let attachment <-collectionRef
            .removeAttachmentFromNFT(
                nftID: fromNFT,
                attachmentType: attachmentType
            )
        destroy attachment
    }
}
 