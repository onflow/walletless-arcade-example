import "FungibleToken"
import "TicketToken"

/// Returns the balance of TicketToken in the Vault at the standar path
/// in the specified address
///
pub fun main(of: Address): UFix64 {
    return getAccount(of).getCapability<&TicketToken.Vault{FungibleToken.Balance}>(
        TicketToken.ReceiverPublicPath
    ).borrow()
    ?.balance
    ?? panic("No TicketToken.Vault found at expected path in account ".concat(of.toString()))
}
