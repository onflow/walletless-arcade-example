import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import MonsterMaker from "../../contracts/MonsterMaker.cdc"

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
