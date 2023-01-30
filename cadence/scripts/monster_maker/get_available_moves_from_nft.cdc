import MonsterMaker from "../../contracts/MonsterMaker.cdc"
import GamingMetadataViews from "../../contracts/GamingMetadataViews.cdc"
import RockPaperScissorsGame from "../../contracts/RockPaperScissorsGame.cdc"

/// Script to get the RockPaperScissors BasicWinLoss data from a given address's NFT

/// Helper method to convert generic array of AnyStruct to an array of RockPaperScissorsGame.Moves
///
pub fun convertToRPSMoves(genericMovesArray: [AnyStruct]): [RockPaperScissorsGame.Moves] {
    let castedMoves: [RockPaperScissorsGame.Moves] = []
    for move in genericMovesArray {
        let castedMove = move as! RockPaperScissorsGame.Moves
        castedMoves.append(castedMove)
    }
    return castedMoves
}


pub fun main(address: Address, id: UInt64): [RockPaperScissorsGame.Moves]? {

    // Borrow ResolverCollection reference
    let collectionPublicRef = getAccount(address)
        .getCapability(MonsterMaker.CollectionPublicPath)
        .borrow<&{MonsterMaker.MonsterMakerCollectionPublic}>()
        ?? panic("Could not borrow a reference to the collection at path: ".concat(MonsterMaker.CollectionPublicPath.toString()))

    // Get the NFT reference if it exists in the reference collection
    if let nftRef = collectionPublicRef.borrowMonsterMaker(id: id) {
        // Get the RPSAssignedMoves attachment
        if let movesRef = nftRef[RockPaperScissorsGame.RPSAssignedMoves] {
            // Resolve the view
            if let movesView = movesRef
                .resolveView(
                    Type<GamingMetadataViews.AssignedMovesView>()
                ) as! GamingMetadataViews.AssignedMovesView? {
                // return the moves contained in the view
                return convertToRPSMoves(genericMovesArray: movesView.moves)
            }
        }
    }

    // Otherwise return nil
    return nil
}