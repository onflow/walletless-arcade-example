import ChildAccount from "../../contracts/ChildAccount.cdc"

/// Returns the child address associated with a public key if any
/// address in the parent's ChildAccountManager.childAccounts have
/// the given originatingPublicKey
///
pub fun main(parentAddress: Address, publicKey: String): Address? {

    let parentAccount = getAccount(parentAddress)

    // Get a ref to the parentAddress's ChildAccountManagerViewer if possible
    if let viewerRef = parentAccount.getCapability<&{
            ChildAccount.ChildAccountManagerViewer
        }>(
            ChildAccount.ChildAccountManagerPublicPath
        ).borrow() {

        let children = viewerRef.getChildAccountAddresses()
        // Iterate over the parent's child account addresses
        for childAddress in children {
            // Get the childAccountInfo for the given address
            if let info = viewerRef.getChildAccountInfo(address: childAddress) {
                // Return the child's address if its originating public key matches the one given
                if info.originatingPublicKey == publicKey {
                    return childAddress
                }
            }
        }
    }

    return nil
}
