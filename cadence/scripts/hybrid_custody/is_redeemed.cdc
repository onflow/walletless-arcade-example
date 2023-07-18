import "HybridCustody"

pub fun main(child: Address, parent: Address): Bool {
    let acct = getAuthAccount(child)
    let owned = acct.borrow<&HybridCustody.OwnedAccount>(from: HybridCustody.OwnedAccountStoragePath)
        ?? panic("owned account not found")

    return owned.getRedeemedStatus(addr: parent) ?? panic("no status found")
}