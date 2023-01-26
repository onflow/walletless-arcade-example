import GamePieceNFT from "../../../contracts/GamePieceNFT.cdc"
import GamingMetadataViews from "../../../contracts/GamingMetadataViews.cdc"
import RockPaperScissorsGame from "../../../contracts/RockPaperScissorsGame.cdc"

/// This transaction resets the win/loss record for the NFT with the specified id
///
transaction(nftID: UInt64) {

    prepare(account: AuthAccount) {
        // Borrow ResolverCollection reference
        let collectionRef = account
            .borrow<&{GamePieceNFT.GamePieceNFTCollectionPublic}>(
                from: GamePieceNFT.CollectionStoragePath
            ) ?? panic("Could not borrow a reference to the collection at path: ".concat(GamePieceNFT.CollectionStoragePath.toString()))

        // Get the NFT reference if it exists in the reference collection
        if let nftRef = collectionRef.borrowGamePieceNFT(id: nftID) {
            // Get the RPSAssignedMoves attachment if exists & reset
            if let winLossRef = nftRef[RockPaperScissorsGame.RPSWinLossRetriever] {
                winLossRef.resetWinLossData()
            }
        }
    }
}
