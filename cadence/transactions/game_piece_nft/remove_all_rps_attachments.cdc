import "NonFungibleToken"
import "GamePieceNFT"
import "RockPaperScissorsGame"

/// Transaction that removes RockPaperScissorsGame related attachments from the desired NFT
///
transaction(fromNFT: UInt64) {
    
    prepare(signer: AuthAccount) {

        // Get a reference to the signer's GamePieceNFT.Collection
        let collectionRef = signer.borrow<&GamePieceNFT.Collection>(
                from: GamePieceNFT.CollectionStoragePath
            ) ?? panic("Could now borrow reference to user's Collection!")

        // If the attachment exists on the NFT, remove & destroy it
        if let retriever <-collectionRef.removeAttachmentFromNFT(
            nftID: fromNFT,
            attachmentType: Type<@RockPaperScissorsGame.RPSWinLossRetriever>()
        ) {
            destroy retriever
        }
        if let moves <-collectionRef.removeAttachmentFromNFT(
            nftID: fromNFT,
            attachmentType: Type<@RockPaperScissorsGame.RPSAssignedMoves>()
        ) {
            destroy moves
        }
    }
}
 