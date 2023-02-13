const TRANSFER_TOKENS = `
import FungibleToken from 0xFungibleToken
import TicketToken from 0xTicketToken

/// This transaction is a template for a transaction that
/// could be used by anyone to send tokens to another account
/// that has been set up to receive tokens.
///
/// The withdraw amount and the account from getAccount
/// would be the parameters to the transaction
transaction(amount: UFix64, to: Address) {

    // The Vault resource that holds the tokens that are being transferred
    let sentVault: @FungibleToken.Vault

    prepare(signer: AuthAccount) {

        // Get a reference to the signer's stored vault
        let vaultRef = signer.borrow<&TicketToken.Vault>(from: TicketToken.VaultStoragePath)
			?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amount)
    }

    execute {

        // Get a reference to the recipient's Receiver
        let receiverRef = getAccount(to)
            .getCapability(TicketToken.ReceiverPublicPath)
            .borrow<&TicketToken.Vault{FungibleToken.Receiver}>()
			?? panic("Could not borrow receiver reference to the recipient's Vault")

        // Deposit the withdrawn tokens in the recipient's receiver
        receiverRef.deposit(from: <-self.sentVault)
    }
}
`

export default TRANSFER_TOKENS
