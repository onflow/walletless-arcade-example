import "FungibleToken"
import "TicketToken"

/// Mints the specified amount of TicketTokens to the given recipient's address,
/// assuming the recipient has a TicketToken.Vault configured in their account
/// and the signer has a TicketToken.Administrator saved in storage.
///
transaction(recipient: Address, amount: UFix64) {
    let tokenAdmin: &TicketToken.Administrator
    let tokenReceiver: &TicketToken.Vault{FungibleToken.Receiver}

    prepare(minterAccount: AuthAccount) {
        self.tokenAdmin = minterAccount
            .borrow<&TicketToken.Administrator>(from: TicketToken.AdminStoragePath)
            ?? panic("Signer is not the token admin")

        self.tokenReceiver = getAccount(recipient).getCapability<
                &TicketToken.Vault{FungibleToken.Receiver}
            >(
                TicketToken.ReceiverPublicPath
            ).borrow()
            ?? panic("Unable to borrow receiver reference")
    }

    execute {
        let minter <- self.tokenAdmin.createNewMinter(allowedAmount: amount)
        let mintedVault <- minter.mintTokens(amount: amount) as! @FungibleToken.Vault

        self.tokenReceiver.deposit(from: <-mintedVault)

        destroy minter
    }
}