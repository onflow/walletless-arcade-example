import "GamePieceNFT"
import "GamingMetadataViews"
import "RockPaperScissorsGame"

/// Script to get the RockPaperScissors BasicWinLoss data from a given address's NFT
///
pub fun main(address: Address, id: UInt64): GamingMetadataViews.BasicWinLoss? {
    let account = getAccount(address)

    // Borrow ResolverCollection reference
    let collectionPublicRef = account
        .getCapability(GamePieceNFT.CollectionPublicPath)
        .borrow<&{GamePieceNFT.GamePieceNFTCollectionPublic}>()
        ?? panic("Could not borrow a reference to the collection at path: ".concat(GamePieceNFT.CollectionPublicPath.toString()))

    // Get the NFT reference if it exists in the reference collection
    if let nftRef = collectionPublicRef.borrowGamePieceNFT(id: id) {
        // Resolve the BasicWinLoss view on the RPSWinLossRetriever attachment
        return nftRef
            .resolveAttachmentView(
                attachmentType: Type<@RockPaperScissorsGame.RPSWinLossRetriever>(),
                view: Type<GamingMetadataViews.BasicWinLoss>()
            ) as! GamingMetadataViews.BasicWinLoss?
    }

    // Otherwise return nil
    return nil
}