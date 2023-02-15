const GET_COLLECTION_IDS = `
import NonFungibleToken from 0xNonFungibleToken
import GamePieceNFT from 0xGamePieceNFT

/// Script to get NFT IDs in an account's collection
///
pub fun main(address: Address): [UInt64] {
    let account = getAccount(address)

    let collectionRef = account
        .getCapability(GamePieceNFT.CollectionPublicPath)
        .borrow<&{NonFungibleToken.CollectionPublic}>()
        ?? panic("Could not borrow a reference to the collection at path: ".concat(GamePieceNFT.CollectionPublicPath.toString()))

    return collectionRef.getIDs()
}
`

export default GET_COLLECTION_IDS
