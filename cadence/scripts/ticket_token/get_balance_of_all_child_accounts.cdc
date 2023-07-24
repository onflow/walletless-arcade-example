import "HybridCustody"
import "FungibleToken"
import "TicketToken"

/// Helper method that returns the TicketToken balance for the specified address. A balance of 0.0 could mean the 
/// balance is 0.0 or a Vault is not configured.
///
pub fun getTicketTokenBalanceSafe(from: Address): UFix64? {
    if let balanceRef = getAccount(from).getCapability<&TicketToken.Vault{FungibleToken.Balance}>(
            TicketToken.ReceiverPublicPath).borrow() {
        return balanceRef.balance
    }
    return nil
}

/// Helper method that returns the TicketToken balance for the specified address, panicking if there is not a 
/// Vault where expected.
///
pub fun getTicketTokenBalance(from: Address): UFix64 {
    let balanceRef = getAccount(from).getCapability<&TicketToken.Vault{FungibleToken.Balance}>(
        TicketToken.ReceiverPublicPath)
        .borrow()
        ?? panic("Could not get a reference TicketToken Vault for address: ".concat(from.toString()))
    return balanceRef.balance
}

/// Returns the TicketToken.Vault.balance of the given account and all linked accounts associated with the specified
/// parent address. If an address is included in the return value, it means it is both a linked account & a TicketToken
/// Vault is configured. Linked accounts not configured with a TicketToken Vault are not included in the return value.
///
pub fun main(parentAddress: Address): {Address: UFix64} {

    // Get the specified account's TicketToken balance
    let accountBalances: {Address: UFix64} = {
        parentAddress: getTicketTokenBalance(from: parentAddress)
    }
    // Get a ref to the parentAddress's HybridCustody.Manager if possible
    if let manager = getAccount(parentAddress).borrow<&HybridCustody.Manager(
        from: HybridCustody.ManagerStoragePath
    ).borrow() {
        // Iterate over the child accounts, adding their balance to the ongoing return mapping
        let childAccounts: [Address] = manager.getLinkedAccountAddresses()
        for address in childAccounts {
            if let balance = getTicketTokenBalanceSafe(from: address) {
                accountBalances.insert(key: address, balance)
            }
        }
    }
    // Return all TicketToken balances
    return accountBalances
}
