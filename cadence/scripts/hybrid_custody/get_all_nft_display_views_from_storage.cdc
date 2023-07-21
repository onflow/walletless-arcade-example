import "NonFungibleToken"
import "MetadataViews"

import "HybridCustody"

/// Custom struct to make interpretation of NFT & Collection data easy client side
pub struct NFTData {
    pub let name: String
    pub let description: String
    pub let thumbnail: String
    pub let resourceID: UInt64
    pub let ownerAddress: Address?
    pub let collectionName: String?
    pub let collectionDescription: String?
    pub let collectionURL: String?
    pub let collectionStoragePathIdentifier: String
    pub let collectionPublicPathIdentifier: String?

    init(
        name: String,
        description: String,
        thumbnail: String,
        resourceID: UInt64,
        ownerAddress: Address?,
        collectionName: String?,
        collectionDescription: String?,
        collectionURL: String?,
        collectionStoragePathIdentifier: String,
        collectionPublicPathIdentifier: String?
    ) {
        self.name = name
        self.description = description
        self.thumbnail = thumbnail
        self.resourceID = resourceID
        self.ownerAddress = ownerAddress
        self.collectionName = collectionName
        self.collectionDescription = collectionDescription
        self.collectionURL = collectionURL
        self.collectionStoragePathIdentifier = collectionStoragePathIdentifier
        self.collectionPublicPathIdentifier = collectionPublicPathIdentifier
    }
}

/// Helper function that retrieves data about all publicly accessible NFTs in an account
///
pub fun getAllViewsFromAddress(_ address: Address): [NFTData] {
    // Get the account
    let account: AuthAccount = getAuthAccount(address)
    // Init for return value
    let data: [NFTData] = []
    // Assign the types we'll need
    let collectionType: Type = Type<@{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>()
    let displayType: Type = Type<MetadataViews.Display>()
    let collectionDisplayType: Type = Type<MetadataViews.NFTCollectionDisplay>()
    let collectionDataType: Type = Type<MetadataViews.NFTCollectionData>()

    // Iterate over each public path
    account.forEachStored(fun (path: StoragePath, type: Type): Bool {
        // Check if it's a Collection we're interested in, if so, get a reference
        if type.isSubtype(of: collectionType) {
            if let collectionRef = account.borrow<
                &{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}
            >(from: path) {
                // Iterate over the Collection's NFTs, continuing if the NFT resolves the views we want
                for id in collectionRef.getIDs() {
                    let resolverRef: &{MetadataViews.Resolver} = collectionRef.borrowViewResolver(id: id)
                    if let display = resolverRef.resolveView(displayType) as! MetadataViews.Display? {
                        let collectionDisplay = resolverRef.resolveView(collectionDisplayType) as! MetadataViews.NFTCollectionDisplay?
                        let collectionData = resolverRef.resolveView(collectionDataType) as! MetadataViews.NFTCollectionData?
                        // Build our NFTData struct from the metadata
                        let nftData = NFTData(
                            name: display.name,
                            description: display.description,
                            thumbnail: display.thumbnail.uri(),
                            resourceID: resolverRef.uuid,
                            ownerAddress: resolverRef.owner?.address,
                            collectionName: collectionDisplay?.name,
                            collectionDescription: collectionDisplay?.description,
                            collectionURL: collectionDisplay?.externalURL?.url,
                            collectionStoragePathIdentifier: path.toString(),
                            collectionPublicPathIdentifier: collectionData?.publicPath?.toString()
                        )
                        // Add it to our data
                        data.append(nftData)
                    }
                }
            }
        }
        return true
    })
    return data
}

/// Script that retrieve data about all publicly accessible NFTs in an account and any of its child accounts
///
/// Note that this script does not consider accounts with exceptionally large collections which would result in memory
/// errors. To compose a script that does cover accounts with a large number of sub-accounts and/or NFTs within those
/// accounts, see example 5 in the NFT Catalog's README: https://github.com/dapperlabs/nft-catalog and adapt for use with
/// HybridCustody.Manager
///
pub fun main(address: Address): {Address: [NFTData]} {
    let allNFTData: {Address: [NFTData]} = {}
    
    // Add all retrieved views to the running mapping indexed on address
    allNFTData.insert(key: address, getAllViewsFromAddress(address))
    
    /* Iterate over any child accounts */ 
    //
    // Get reference to HybridCustody.Manager if it exists
    if let manager = getAuthAccount(address).borrow<&HybridCustody.Manager>(from: HybridCustody.ManagerStoragePath) {
        // Iterate over each child account
        for childAddress in manager.getChildAddresses() {
            if !allNFTData.containsKey(childAddress) {
                // Insert the NFT metadata for those NFTs in each child account indexing on the account's address
                allNFTData.insert(key: childAddress, getAllViewsFromAddress(childAddress))
            }
        }
    }
    return allNFTData 
}
