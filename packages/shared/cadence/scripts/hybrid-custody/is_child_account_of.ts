const IS_CHILD_ACCOUNT_OF = `
import HybridCustody from 0xHybridCustody

pub fun main(child: Address, parent: Address): Bool {
    let acct = getAuthAccount(child)
    let owned = acct.borrow<&HybridCustody.OwnedAccount>(from: HybridCustody.OwnedAccountStoragePath)
        ?? panic("owned account not found")

    return owned.isChildOf(parent)
}
`
export default IS_CHILD_ACCOUNT_OF