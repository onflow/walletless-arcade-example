const GET_BALANCE_OF_ALL_CHILD_ACCOUNTS = `
import LinkedAccounts from 0xLinkedAccounts
import FungibleToken from 0xFungibleToken
import TicketToken from 0xTicketToken

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
        parentAddress: getTicketTokenBalance(parentAddress)
    }
    // Get a ref to the parentAddress's LinkedAccounts.Collection if possible
    if let viewerRef = getAccount(parentAddress).getCapability<&LinkedAccounts.Collection{LinkedAccounts.CollectionPublic}>(
        LinkedAccounts.CollectionPublicPath).borrow() {
        // Iterate over the linked accounts, adding their balance to the ongoing return mapping
        let linkedAccounts: [Address] = viewerRef.getLinkedAccountAddresses()
        for address in linkedAccounts {
            if let balance = getTicketTokenBalanceSafe(address) {
                accountBalances.insert(key: address, balance)
            }
        }
    }
    // Return all TicketToken balances
    return accountBalances
}
`

export default GET_BALANCE_OF_ALL_CHILD_ACCOUNTS
