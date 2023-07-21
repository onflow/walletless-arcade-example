import "AccountCreator"
import "HybridCustody"

/// Takes the address where a AccountCreator.CreatorPublic Capability lives, a public key as a String, and the address
/// where a HybridCustody.ManagerPublic Capability lives and return whether the given public key is tied to an
/// account that is an active child account of the specified parent address and the given public key is active on the 
/// account.
///
/// This would be helpful for our demo dapp determining if the key it has is valid for a user's child account or a 
/// child account needs to be created & linked
///
pub fun main(creatorAddress: Address, pubKey: String, parentAddress: Address): Bool {
    // Get a reference to the CreatorPublic Capability from creatorAddress
    if let creator = getAccount(creatorAddress).getCapability<&AccountCreator.Creator{AccountCreator.CreatorPublic}>(
            AccountCreator.CreatorPublicPath
        ).borrow() {
        // Get the child address if it exists
        if let childAddress = creator.getAddressFromPublicKey(publicKey: pubKey) {
            // Get a reference to the HybridCustody.ManagerPublic Capability from parentAddress
            if let manager = getAccount(parentAddress).getCapability<&HybridCustody.Manager{HybridCustody.ManagerPublic}>(
                    HybridCustody.ManagerPublicPath
                ).borrow() {
                return manager.isLinkActive(onAddress: childAddress) &&
                    AccountCreator.isKeyActiveOnAccount(publicKey: pubKey, address: childAddress)
            }
        }
    }
    return false
}
 