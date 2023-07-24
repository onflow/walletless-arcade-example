import "HybridCustody"

pub fun main(parent: Address, child: Address): Bool {
    let acct = getAuthAccount(parent)
    let m = acct.borrow<&HybridCustody.Manager>(from: HybridCustody.ManagerStoragePath)
        ?? panic("manager not found")

    return m.borrowAccount(addr: child) != nil
}