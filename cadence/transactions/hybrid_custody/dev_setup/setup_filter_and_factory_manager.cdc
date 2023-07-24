import "CapabilityFilter"
import "CapabilityFactory"
import "NFTCollectionPublicFactory"
import "NFTProviderAndCollectionFactory"
import "NFTProviderFactory"
import "FTProviderFactory"
import "FTAllFactory"

import "NonFungibleToken"
import "FungibleToken"

import "TicketToken"

/* --- Helper Methods --- */
//
/// Returns a type identifier for an NFT Collection
///
access(all) fun deriveCollectionOrVaultTypeIdentifier(_ contractAddress: Address, _ contractName: String, isCollection: Bool): String {
    let prefix = "A.".concat(withoutPrefix(contractAddress.toString())).concat(".").concat(contractName)
    if isCollection {
        return prefix.concat(".Collection")
    } else {
        return prefix.concat(".Vault")
    }
}

/// Taken from AddressUtils private method
///
access(all) fun withoutPrefix(_ input: String): String{
    var address = input

    //get rid of 0x
    if address.length > 1 && address.utf8[1] == 120 {
        address = address.slice(from: 2, upTo: address.length)
    }

    //ensure even length
    if address.length % 2 == 1{
        address="0".concat(address)
    }
    return address
}

/* --- Transaction Block --- */
//
/// This transaction can be used by most developers implementing HybridCustody as the single pre-requisite transaction
/// to setup filter functionality between linked parent and child accounts.
///
/// Creates a CapabilityFactory Manager and CapabilityFilter.AllowlistFilter in the signing account (if needed), adding
/// NFTCollectionPublicFactory, NFTProviderAndCollectionFactory, & NFTProviderFactory to the CapabilityFactory Manager
/// and the Collection Type to the CapabilityFilter.AllowlistFilter
/// 
/// For more info, see docs at https://developers.onflow.org/docs/hybrid-custody/
////
transaction(nftContractAddress: Address, nftContractName: String, ftContractAddress: Address, ftContractName: String) {
    prepare(acct: AuthAccount) {
        
        /* --- CapabilityFactory Manager configuration --- */
        //
        if acct.borrow<&AnyResource>(from: CapabilityFactory.StoragePath) == nil {
            let f <- CapabilityFactory.createFactoryManager()
            acct.save(<-f, to: CapabilityFactory.StoragePath)
        }

        if !acct.getCapability<&CapabilityFactory.Manager{CapabilityFactory.Getter}>(CapabilityFactory.PrivatePath).check() {
            acct.unlink(CapabilityFactory.PublicPath)
            acct.link<&CapabilityFactory.Manager{CapabilityFactory.Getter}>(CapabilityFactory.PublicPath, target: CapabilityFactory.StoragePath)
        }

        assert(
            acct.getCapability<&CapabilityFactory.Manager{CapabilityFactory.Getter}>(CapabilityFactory.PublicPath).check(),
            message: "CapabilityFactory is not setup properly"
        )

        let factoryManager = acct.borrow<&CapabilityFactory.Manager>(from: CapabilityFactory.StoragePath)
            ?? panic("CapabilityFactory Manager not found")

        // Add NFT-related Factories to the Manager
        factoryManager.updateFactory(Type<&{NonFungibleToken.CollectionPublic}>(), NFTCollectionPublicFactory.Factory())
        factoryManager.updateFactory(Type<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(), NFTProviderAndCollectionFactory.Factory())
        factoryManager.updateFactory(Type<&{NonFungibleToken.Provider}>(), NFTProviderFactory.Factory())
        factoryManager.updateFactory(Type<&{FungibleToken.Provider}>(), FTProviderFactory.Factory())
        factoryManager.updateFactory(Type<&{FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance}>(), FTAllFactory.Factory())

        /* --- AllowlistFilter configuration --- */
        //
        if acct.borrow<&CapabilityFilter.AllowlistFilter>(from: CapabilityFilter.StoragePath) == nil {
            acct.save(<-CapabilityFilter.create(Type<@CapabilityFilter.AllowlistFilter>()), to: CapabilityFilter.StoragePath)
        }

        if !acct.getCapability<&CapabilityFilter.AllowlistFilter{CapabilityFilter.Filter}>(CapabilityFilter.PublicPath).check() {
            acct.unlink(CapabilityFilter.PublicPath)
            acct.link<&CapabilityFilter.AllowlistFilter{CapabilityFilter.Filter}>(CapabilityFilter.PublicPath, target: CapabilityFilter.StoragePath)
        }

        assert(
            acct.getCapability<&CapabilityFilter.AllowlistFilter{CapabilityFilter.Filter}>(CapabilityFilter.PublicPath).check(),
            message: "AllowlistFilter is not setup properly"
        )

        let filter = acct.borrow<&CapabilityFilter.AllowlistFilter>(from: CapabilityFilter.StoragePath)
            ?? panic("AllowlistFilter does not exist")

        // Construct an NFT Collection Type from the provided args & add to the AllowlistFilter
        let collectionIdentifier = deriveCollectionOrVaultTypeIdentifier(nftContractAddress, nftContractName, isCollection: true)
        let collectionType = CompositeType(collectionIdentifier)
            ?? panic("Problem constructing CompositeType from given NFT contract address and name from identifier: ".concat(collectionIdentifier))
        filter.addType(collectionType)
        // Construct an FT Vault Type from the provided args & add to the AllowlistFilter
        let vaultIdentifier = deriveCollectionOrVaultTypeIdentifier(ftContractAddress, ftContractName, isCollection: false)
        let vaultType = CompositeType(vaultIdentifier)
            ?? panic("Problem vaultIdentifier CompositeType from given FungibleToken contract address and name from identifier: ".concat(vaultIdentifier))
        filter.addType(vaultType)
    }
}
