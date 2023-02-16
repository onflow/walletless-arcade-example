
import GamePieceNFT from "../../contracts/GamePieceNFT.cdc"
import GamingMetadataViews from "../../contracts/GamingMetadataViews.cdc"
import RockPaperScissorsGame from "../../contracts/RockPaperScissorsGame.cdc"

/// Script to get the RockPaperScissors BasicWinLoss data from a given address's NFT
///
pub fun main(address: Address, id: UInt64): [RockPaperScissorsGame.Moves]? {
    let account = getAccount(address)

    // Borrow ResolverCollection reference
    let collectionPublicRef = account
        .getCapability(GamePieceNFT.CollectionPublicPath)
        .borrow<&{GamePieceNFT.GamePieceNFTCollectionPublic}>()
        ?? panic("Could not borrow a reference to the collection at path: ".concat(GamePieceNFT.CollectionPublicPath.toString()))

    // Get the NFT reference if it exists in the reference collection
    if let nftRef = collectionPublicRef.borrowGamePieceNFT(id: id) {
        // Get the AssignedMovesView from the NFT & return
        if let movesView = nftRef
            .resolveAttachmentView(
                attachmentType: Type<@RockPaperScissorsGame.RPSAssignedMoves>(),
                view: Type<GamingMetadataViews.AssignedMovesView>()
            ) as! GamingMetadataViews.AssignedMovesView? {
            return movesView.moves as! [RockPaperScissorsGame.Moves]
        }
    }

    // Otherwise return nil
    return nil
}