import "FungibleToken"
import "MetadataViews"
import "HybridCustody"

/// Returns a mapping of balances indexed on the Type of resource containing the balance
///
pub fun getAllBalancesInStorage(_ address: Address): {Type: UFix64} {
    // Get the account
    let account: AuthAccount = getAuthAccount(address)
    // Init for return value
    let balances: {Type: UFix64} = {}
    // Track seen Types in array
    let seen: [Type] = []
    // Assign the type we'll need
    let balanceType: Type = Type<@{FungibleToken.Balance}>()
    // Iterate over all stored items & get the path if the type is what we're looking for
    account.forEachStored(fun (path: StoragePath, type: Type): Bool {
        if type.isInstance(balanceType) || type.isSubtype(of: balanceType) {
            // Get a reference to the resource & its balance
            let vaultRef = account.borrow<&{FungibleToken.Balance}>(from: path)!
            // Insert a new values if it's the first time we've seen the type
            if !seen.contains(type) {
                balances.insert(key: type, vaultRef.balance)
            } else {
                // Otherwise just update the balance of the vault (unlikely we'll see the same type twice in
                // the same account, but we want to cover the case)
                balances[type] = balances[type]! + vaultRef.balance
            }
        }
        return true
    })
    return balances
}

/// Queries for FT.Vault balance of all FT.Vaults in the specified account and all of its associated accounts
///
pub fun main(address: Address): {Address: {Type: UFix64}} {

    // Get the balance for the given address
    let balances: {Address: {Type: UFix64}} = { address: getAllBalancesInStorage(address) }
    // Tracking Addresses we've come across to prevent overwriting balances (more efficient than checking dict entries (?))
    let seen: [Address] = [address]
    
    /* Iterate over any associated accounts */ 
    //
    if let managerRef = getAuthAccount(address)
        .borrow<&HybridCustody.Manager>(from: HybridCustody.ManagerStoragePath) {
        
        for childAccount in managerRef.getChildAddresses() {
            balances.insert(key: childAccount, getAllBalancesInStorage(address))
            seen.append(childAccount)
        }

        for ownedAccount in managerRef.getOwnedAddresses() {
            if seen.contains(ownedAccount) == false {
                balances.insert(key: ownedAccount, getAllBalancesInStorage(address))
                seen.append(ownedAccount)
            }
        }
    }

    return balances 
}
 