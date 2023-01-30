const IS_GAME_PIECE_NFT_COLLECTION_CONFIGURED = `
import NonFungibleToken from 0xNonFungibleToken
import MonsterMaker from 0xMonsterMaker

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
`

export default IS_GAME_PIECE_NFT_COLLECTION_CONFIGURED
