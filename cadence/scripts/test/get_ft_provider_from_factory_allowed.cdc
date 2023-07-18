import "MetadataViews"
import "FungibleToken"

import "CapabilityFilter"
import "CapabilityFactory"

import "TicketToken"

pub fun main(address: Address, providerPath: PrivatePath): Bool {
    let acct = getAuthAccount(address)
    let ref = &acct as &AuthAccount

    let factoryManager = acct.borrow<&CapabilityFactory.Manager>(from: CapabilityFactory.StoragePath)
        ?? panic("Problem borrowing CapabilityFactory Manager")
    let factory = factoryManager.getFactory(Type<&{FungibleToken.Provider}>())
        ?? panic("No factory for FungibleToken Provider Factory found")

    let provider = factory.getCapability(acct: ref, path: providerPath) as! Capability<&{FungibleToken.Provider}>
    assert(provider.borrow() != nil, message: "Invalid FungibleToken Provider Capability retrieved")

    let filter = acct.borrow<&CapabilityFilter.AllowlistFilter>(from: CapabilityFilter.StoragePath)
        ?? panic("Problem borrowing CapabilityFilter AllowlistFilter")

    return filter.allowed(cap: provider)
}