const GET_COLLECTION_IDS = `
import NonFungibleToken from 0xNonFungibleToken
import MetadataViews from 0xMetadataViews
import MonsterMaker from 0xMonsterMaker

/// Returns an array of Display structs containing MonsterMaker.NFT metadata
/// for all NFTs in the specified Address's collection
///
pub fun main(address: Address): [MetadataViews.Display] {
    let collectionRef = getAccount(address).getCapability<
            &MonsterMaker.Collection{MetadataViews.ResolverCollection}
        >(
            MonsterMaker.CollectionPublicPath
        ).borrow()
        ?? panic("Could not borrow capability from public collection")
    
    let ids = collectionRef.getIDs()

    let displays : [MetadataViews.Display] = []
    let viewType: Type = Type<MetadataViews.Display>()

    for id in ids {
        let resolverRef = collectionRef.borrowViewResolver(id: id) 
        if let displayView = resolverRef.resolveView(viewType){
            displays.append(displayView as! MetadataViews.Display)
        }
    }

    return displays
}
`

export default GET_COLLECTION_IDS
