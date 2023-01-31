import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import MonsterMaker from "../../contracts/MonsterMaker.cdc"

/// Script to check if MonsterMakerCollectionPublic is configured at
/// a given address
///
pub fun main(address: Address): Bool {
    return getAccount(address).getCapability<
        &MonsterMaker.Collection{MonsterMaker.MonsterMakerCollectionPublic}>
    (
        MonsterMaker.CollectionPublicPath
    ).check()
}
