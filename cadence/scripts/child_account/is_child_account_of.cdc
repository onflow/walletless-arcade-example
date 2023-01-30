import ChildAccount from "../../contracts/ChildAccount.cdc"

/// This script allows one to determine if a given account is a child 
/// account of the specified parent account as the parent-child account
/// relationship is defined in the ChildAccount contract
///
pub fun main(parent: Address, child: Address): Bool {

    // Get a reference to the ChildAccountManagerViewer in parent's account
    let viewerRef = getAccount(parent)
        .getCapability<&{
            ChildAccount.ChildAccountManagerViewer
        }>(
            ChildAccount.ChildAccountManagerPublicPath
        ).borrow()
        ?? panic("Could not borrow reference to parent's ChildAccountManagerViewer")
    
    // If the given child address is one of the parent's children account, check if it's active
    if viewerRef.getChildAccountAddresses().contains(child) {
        let childAccount = getAccount(child)
        let childAccountTagPublicRef = childAccount
            .getCapability<
                &{ChildAccount.ChildAccountTagPublic}
            >(
                ChildAccount.ChildAccountTagPublicPath
            ).borrow()
            ?? panic("Could not get reference to ChildAccountTagPublic reference for ".concat(child.toString()))
        return childAccountTagPublicRef.isCurrentlyActive()
    }
    return false
}
 