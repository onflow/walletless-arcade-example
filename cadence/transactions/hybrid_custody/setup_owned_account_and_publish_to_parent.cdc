#allowAccountLinking

import "MetadataViews"

import "RockPaperScissorsGame"

import "HybridCustody"
import "CapabilityFactory"
import "CapabilityFilter"
import "CapabilityDelegator"

/// This transaction configures an OwnedAccount in the signer if needed and with an attached MetadataViews.Display
/// from the RPSGame.info. The transaction then proceeds to create a ChildAccount using CapabilityFactory.Manager
/// and CapabilityFilter.Filter Capabilities from the given addresses, and publishes a Capability on said ChildAccount
/// to the specified parent account.
///
transaction(
    parent: Address,
    factoryAddress: Address,
    filterAddress: Address
) {
    
    prepare(acct: AuthAccount) {
        // Configure OwnedAccount if it doesn't exist
        if acct.borrow<&HybridCustody.OwnedAccount>(from: HybridCustody.OwnedAccountStoragePath) == nil {
            var acctCap = acct.getCapability<&AuthAccount>(HybridCustody.LinkedAccountPrivatePath)
            if !acctCap.check() {
                acctCap = acct.linkAccount(HybridCustody.LinkedAccountPrivatePath)!
            }
            let ownedAccount <- HybridCustody.createOwnedAccount(acct: acctCap)
            acct.save(<-ownedAccount, to: HybridCustody.OwnedAccountStoragePath)
        }

        // check that paths are all configured properly
        acct.unlink(HybridCustody.OwnedAccountPrivatePath)
        acct.link<&HybridCustody.OwnedAccount{HybridCustody.BorrowableAccount, HybridCustody.OwnedAccountPublic, MetadataViews.Resolver}>(HybridCustody.OwnedAccountPrivatePath, target: HybridCustody.OwnedAccountStoragePath)

        acct.unlink(HybridCustody.OwnedAccountPublicPath)
        acct.link<&HybridCustody.OwnedAccount{HybridCustody.OwnedAccountPublic, MetadataViews.Resolver}>(HybridCustody.OwnedAccountPublicPath, target: HybridCustody.OwnedAccountStoragePath)

        let owned = acct.borrow<&HybridCustody.OwnedAccount>(from: HybridCustody.OwnedAccountStoragePath)
            ?? panic("owned account not found")

        // Set the display metadata for the OwnedAccount
        let info = RockPaperScissorsGame.info
        let display = MetadataViews.Display(
                name: info.name,
                description: info.description,
                thumbnail: info.thumbnail
            )
        owned.setDisplay(display)

        // Get CapabilityFactory & CapabilityFilter Capabilities
        let factory = getAccount(factoryAddress).getCapability<&CapabilityFactory.Manager{CapabilityFactory.Getter}>(CapabilityFactory.PublicPath)
        assert(factory.check(), message: "factory address is not configured properly")

        let filter = getAccount(filterAddress).getCapability<&{CapabilityFilter.Filter}>(CapabilityFilter.PublicPath)
        assert(filter.check(), message: "capability filter is not configured properly")

        // Finally publish a ChildAccount capability on the signing account to the specified parent
        owned.publishToParent(parentAddress: parent, factory: factory, filter: filter)
    }
}