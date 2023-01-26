// import ChildAccount from "../../contracts/ChildAccount.cdc"
import ChildAccount from "../../contracts/ChildAuthAccount.cdc"

/// Takes the address where a ChildAccountCreator Capability lives, a public key as
/// a String, and the address where a ChildAccountManagerViewer Capability lives
/// and return whether the given public key is tied to an account that is an active
/// child account of the specified parent address.
///
/// This would be helpful for a dapp determining if the key it has is valid for a user's
/// child account or a child account needs to be created & linked
///
pub fun main(creatorAddress: Address, pubKey: String, parentAddress: Address): Bool {
    // Get a reference to the ChildAccountCreatorPublic Capability from creatorAddress
    if let creatorRef = getAccount(creatorAddress)
        .getCapability<
            &{ChildAccount.ChildAccountCreatorPublic}
        >(
            ChildAccount.ChildAccountCreatorPublicPath
        ).borrow() {
        // Get the child address if it exists
        if let childAddress = creatorRef.getAddressFromPublicKey(publicKey: pubKey) {
            // Get a reference to the ChildAccountManagerViewer Capability from parentAddress
            if let viewerRef = getAccount(creatorAddress)
                .getCapability<
                    &{ChildAccount.ChildAccountManagerViewer}
                >(
                    ChildAccount.ChildAccountManagerPublicPath
                ).borrow() {
                // Return whether the address is a child of the parentAddress & check whether it's set as active
                return viewerRef.getChildAccountAddresses().contains(childAddress) &&
                    (viewerRef.getChildAccountTagRef(address: childAddress)?.isCurrentlyActive() ?? false)
            }
        }
    }
    return nil
}