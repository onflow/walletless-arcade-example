const GET_COLLECTION_IDS = `
import NonFungibleToken from 0xNonFungibleToken
import MonsterMaker from 0xMonsterMaker

/// Script to get NFT IDs in an account's collection
///
pub fun main(address: Address): [UInt64] {
    let account = getAccount(address)

    let collectionRef = account
        .getCapability(MonsterMaker.CollectionPublicPath)
        .borrow<&MonsterMaker.Collection{NonFungibleToken.CollectionPublic}>()
        ?? panic("Could not borrow a reference to the collection at path: ".concat(MonsterMaker.CollectionPublicPath.toString()))

    return collectionRef.getIDs()
}

`

export default GET_COLLECTION_IDS
