import ChildAccount from "../../contracts/ChildAccount.cdc"

/// Returns the types a child account has been granted via
/// its ChildAccountTag
///
pub fun main(childAddress: Address): [Type]? {

    let childAccount = getAccount(childAddress)

    // Get a ref to the parentAddress's ChildAccountManagerViewer if possible
    if let tagRef = childAccount.getCapability<&{
            ChildAccount.ChildAccountTagPublic
        }>(
            ChildAccount.ChildAccountTagPublicPath
        ).borrow() {

        return tagRef.getGrantedCapabilityTypes()
    }

    return nil
}
