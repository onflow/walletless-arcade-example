import "MetadataViews"
import "NonFungibleToken"

import "CapabilityFilter"
import "CapabilityFactory"
import "NFTProviderFactory"

import "GamePieceNFT"

/// Determines if GamePieceNFT Provider both has a Factory at the ruleAddr and is allowed by the AllowlistFilter found in
/// the given account housing the CapabilityFactory Manager and the CapabilityFilter AllowlistFilter.
///
pub fun main(address: Address): Bool {
    let acct = getAuthAccount(address)
    let ref = &acct as &AuthAccount

    let factoryManager = acct.borrow<&CapabilityFactory.Manager>(from: CapabilityFactory.StoragePath)
        ?? panic("Problem borrowing CapabilityFactory Manager")
    let factory = factoryManager.getFactory(Type<&{NonFungibleToken.Provider}>())
        ?? panic("No factory for NFT Provider Factory found")

    let d = GamePieceNFT.resolveView(Type<MetadataViews.NFTCollectionData>())! as! MetadataViews.NFTCollectionData
    let provider = factory.getCapability(acct: ref, path: d.providerPath) as! Capability<&{NonFungibleToken.Provider}>
    assert(provider.borrow() != nil, message: "Invalid NonFungibleToken Provider Capability retrieved")

    let filter = acct.borrow<&CapabilityFilter.AllowlistFilter>(from: CapabilityFilter.StoragePath)
        ?? panic("Problem borrowing CapabilityFilter AllowlistFilter")
    
    return filter.allowed(cap: provider)
}