const IS_CHILD_ACCOUNT_MANAGER_CONFIGURED = `
import ChildAccount from 0xChildAccount

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
`
export default IS_CHILD_ACCOUNT_MANAGER_CONFIGURED
