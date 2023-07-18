import "NonFungibleToken"
import "GamePieceNFT"
import "RockPaperScissorsGame"

/// Transaction that removes RockPaperScissorsGame related attachment
/// from the desired NFT. Note that only RPSWinLossRetriever and 
/// RPSAssignedMoves types are supported by this transaction as those are
/// the concrete attachments defined in the RockPaperScissorsGame contract.
///
transaction(fromNFT: UInt64, attachmentType: Type) {
    
    prepare(signer: AuthAccount) {
        pre {
            attachmentType == Type<&RockPaperScissorsGame.RPSWinLossRetriever>() ||
            attachmentType == Type<&RockPaperScissorsGame.RPSAssignedMoves>():
                "Given attachment Type not supported by this transaction!"
        }

        // Get a reference to the signer's GamePieceNFT.Collection
        let collectionRef = signer
            .borrow<&
                GamePieceNFT.Collection
            >(
                from: GamePieceNFT.CollectionStoragePath
            ) ?? panic("Could now borrow reference to user's Collection!")
        // Get base NFT
        let nft <- collectionRef.withdraw(withdrawID: fromNFT)

        // Remove desired attachment type by stating its static type (a requirement for attaching
        // or removing native attachments)
        if attachmentType == Type<&RockPaperScissorsGame.RPSWinLossRetriever>() &&
            nft[RockPaperScissorsGame.RPSWinLossRetriever] != nil {
            remove RockPaperScissorsGame.RPSWinLossRetriever from nft
        } else if attachmentType == Type<&RockPaperScissorsGame.RPSAssignedMoves>() &&
            nft[RockPaperScissorsGame.RPSAssignedMoves] != nil {
            remove RockPaperScissorsGame.RPSAssignedMoves from nft
        }

        // Deposit the NFT back to the signer's Collection, now without the attachment
        collectionRef.deposit(token: <-nft)
    }
}
 