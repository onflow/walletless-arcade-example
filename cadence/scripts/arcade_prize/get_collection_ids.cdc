import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import ArcadePrize from "../../contracts/ArcadePrize.cdc"

/// Script to get NFT IDs in an account's collection
///
pub fun main(address: Address): [UInt64] {

    let collectionRef = getAccount(address)
        .getCapability(ArcadePrize.CollectionPublicPath)
        .borrow<&ArcadePrize.Collection{NonFungibleToken.CollectionPublic}>()
        ?? panic("Could not borrow a reference to the collection at path: ".concat(ArcadePrize.CollectionPublicPath.toString()))

    return collectionRef.getIDs()
}
