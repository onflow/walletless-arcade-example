const GET_BALANCE_OF_ALL_CHILD_ACCOUNTS = `
import ChildAccount from 0xChildAccount
import FungibleToken from 0xFungibleToken
import TicketToken from 0xTicketToken

/// Returns the TicketToken.Vault.balance of all child accounts
/// associated with the specified parent address
///
pub fun main(parentAddress: Address): {Address: UFix64} {

    let parentAccount = getAccount(parentAddress)

    // Get a ref to the parentAddress's ChildAccountManagerViewer if possible
    let viewerRef = parentAccount.getCapability<&{
            ChildAccount.ChildAccountManagerViewer
        }>(
            ChildAccount.ChildAccountManagerPublicPath
        ).borrow()
        ?? panic("Could not get a reference to the ChildAccountManagerViewer at address ".concat(parentAddress.toString()))

    let childAddresses: [Address] = viewerRef.getChildAccountAddresses()
    let accountBalances: {Address: UFix64} = {}
    for child in childAddresses {
        if let balanceRef = getAccount(child).getCapability<
            &TicketToken.Vault{FungibleToken.Balance}
        >(
            TicketToken.ReceiverPublicPath
        ).borrow() {
            accountBalances.insert(key: child, balanceRef.balance)
        }
    }
    return accountBalances
}
`

export default GET_BALANCE_OF_ALL_CHILD_ACCOUNTS
