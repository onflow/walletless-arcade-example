import "FungibleToken"
import "MetadataViews"

import "TicketToken"

/// Validates correct configuration of TicketToken resource & Capabilities
///
pub fun main(address: Address): Bool {
    
    let public = getAccount(address).getCapability<&TicketToken.Vault{FungibleToken.Receiver, FungibleToken.Balance, MetadataViews.Resolver}>(
            TicketToken.ReceiverPublicPath
        )
    let private = getAuthAccount(address).getCapability<&TicketToken.Vault{FungibleToken.Provider}>(
            TicketToken.ProviderPrivatePath
        )

    return public.check() && private.check()
}