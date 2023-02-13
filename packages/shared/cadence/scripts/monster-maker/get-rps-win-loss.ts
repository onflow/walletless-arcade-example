const GET_RPS_WIN_LOSS = `
import MonsterMaker from 0xMonsterMaker
import GamingMetadataViews from 0xGamingMetadataViews
import RockPaperScissorsGame from 0xRockPaperScissorsGame

/// Script to get the RockPaperScissors BasicWinLoss data from a given address's
/// MonsterMaker NFT
///
pub fun main(address: Address, id: UInt64): GamingMetadataViews.BasicWinLoss? {

    // Borrow ResolverCollection reference
    let collectionPublicRef = getAccount(address)
        .getCapability(MonsterMaker.CollectionPublicPath)
        .borrow<&MonsterMaker.Collection{MonsterMaker.MonsterMakerCollectionPublic}>()
        ?? panic("Could not borrow a reference to the collection at path: ".concat(MonsterMaker.CollectionPublicPath.toString()))

    // Get the NFT reference if it exists in the reference collection
    if let nftRef = collectionPublicRef.borrowMonsterMaker(id: id) {
        // Get the RPSAssignedMoves attachment
        if let winLossRef = nftRef[RockPaperScissorsGame.RPSWinLossRetriever] {
            // Resolve the BasicWinLoss view on the RPSWinLossRetriever attachment
            return winLossRef
                .resolveView(
                    Type<GamingMetadataViews.BasicWinLoss>()
                ) as! GamingMetadataViews.BasicWinLoss?
        }
    }

    // Otherwise return nil
    return nil
}
`

export default GET_RPS_WIN_LOSS
