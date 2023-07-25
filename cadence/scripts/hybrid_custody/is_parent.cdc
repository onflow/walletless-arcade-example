import "HybridCustody"

pub fun main(child: Address, parent: Address): Bool {
    let acct = getAuthAccount(child)
    return acct.borrow<&HybridCustody.OwnedAccount>(from: HybridCustody.OwnedAccountStoragePath)
        ?.isChildOf(parent)
        ?? false
}