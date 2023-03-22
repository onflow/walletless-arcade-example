const IS_CHILD_ACCOUNT_OF = `
import LinkedAccounts from 0xLinkedAccounts

/// This script allows one to determine if a given account is a child account of the specified parent account as the
/// parent-child account relationship is defined in the LinkedAccounts contract.
///
pub fun main(parent: Address, child: Address): Bool {

    // Get a reference to the LinkedAccounts.CollectionPublic in parent's account
    if let collectionRef = getAccount(parent).getCapability<
        &LinkedAccounts.Collection{LinkedAccounts.CollectionPublic}>(
            LinkedAccounts.CollectionPublicPath
        ).borrow() {
        // Return whether the link between given accounts is active
        return collectionRef.isLinkActive(onAddress: child)
    }
    return false
}
 
`
export default IS_CHILD_ACCOUNT_OF
