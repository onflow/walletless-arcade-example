const IS_CHILD_ACCOUNT_OF = `
import HybridCustody from 0xHybridCustody

pub fun main(child: Address, parent: Address): Bool {
    let acct = getAuthAccount(child)
    return acct.borrow<&HybridCustody.OwnedAccount>(from: HybridCustody.OwnedAccountStoragePath)
        ?.isChildOf(parent)
        ?? false
}
`
export default IS_CHILD_ACCOUNT_OF