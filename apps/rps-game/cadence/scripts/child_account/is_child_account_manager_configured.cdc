import ChildAccount from "../../contracts/ChildAccount.cdc"

/// This script allows one to determine if a given account has a
/// ChildAccountManager configured
///
pub fun main(parent: Address): Bool {

    // Return whether the ChildAccountViewer is configured as a test of whether
    // the ChildAccountManager is configured at the given address
    return getAccount(parent)
        .getCapability<&{
            ChildAccount.ChildAccountManagerViewer
        }>(
            ChildAccount.ChildAccountManagerPublicPath
        ).check()
}
 