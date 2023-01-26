import ChildAccount from "../../contracts/ChildAccount.cdc"

/// Returns the child address associated with a public key if any
/// address in the parent's ChildAccountManager.childAccounts have
/// the given originatingPublicKey
///
pub fun main(parentAddress: Address): [Address] {

    let parentAccount = getAccount(parentAddress)

    // Get a ref to the parentAddress's ChildAccountManagerViewer if possible
    let viewerRef = parentAccount.getCapability<&{
            ChildAccount.ChildAccountManagerViewer
        }>(
            ChildAccount.ChildAccountManagerPublicPath
        ).borrow()
        ?? panic("Could not get a reference to the ChildAccountManagerViewer at address ".concat(parentAddress.toString()))

    return viewerRef.getChildAccountAddresses()
}
