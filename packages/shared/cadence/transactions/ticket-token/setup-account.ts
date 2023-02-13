const SETUP_ACCOUNT = `
import FungibleToken from 0xFungibleToken
import TicketToken from 0xTicketToken
import MetadataViews from 0xMetadataViews

/// This transaction creates a TicketToken.Vault, saves it in signer's storage
/// and links public & private capabilities
///
transaction {

    prepare(signer: AuthAccount) {

        if signer.borrow<&TicketToken.Vault>(from: TicketToken.VaultStoragePath) == nil {
            // Create a new flowToken Vault and put it in storage
            signer.save(<-TicketToken.createEmptyVault(), to: TicketToken.VaultStoragePath)
        }

        if !signer.getCapability<&TicketToken.Vault{FungibleToken.Receiver, FungibleToken.Balance, MetadataViews.Resolver}>(
            TicketToken.ReceiverPublicPath
        ).check() {
            // Unlink any capability that may exist there
            signer.unlink(TicketToken.ReceiverPublicPath)
            // Create a public capability to the Vault that only exposes the deposit function
            // & balance field through the Receiver & Balance interface
            signer.link<&TicketToken.Vault{FungibleToken.Receiver, FungibleToken.Balance, MetadataViews.Resolver}>(
                TicketToken.ReceiverPublicPath,
                target: TicketToken.VaultStoragePath
            )
        }

        if !signer.getCapability<&TicketToken.Vault{FungibleToken.Provider}>(
            TicketToken.ProviderPrivatePath
        ).check() {
            // Unlink any capability that may exist there
            signer.unlink(TicketToken.ProviderPrivatePath)
            // Create a private capability to the Vault that only exposes the withdraw function
            // through the Provider interface
            signer.link<&TicketToken.Vault{FungibleToken.Provider}>(
                TicketToken.ProviderPrivatePath,
                target: TicketToken.VaultStoragePath
            )
        }
    }
}
`

export default SETUP_ACCOUNT
