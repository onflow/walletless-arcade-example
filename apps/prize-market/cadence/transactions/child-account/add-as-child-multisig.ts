const ADD_AS_CHILD_MULTISIG = `
import NonFungibleToken from 0xNonFungibleToken
import MetadataViews from 0xMetadataViews
import MonsterMaker from 0xMonsterMaker
import ChildAccount from 0xChildAccount
import FungibleToken from 0xFungibleToken
import TicketToken from 0xTicketToken

// TODO: Add check on existing child of parent
/// Adds the labeled child account as a Child Account in the parent accounts'
/// ChildAccountManager resource. The parent maintains an AuthAccount Capability
/// on the child's account. Requires transaction be signed by both parties so that
/// the GamePlayer resource can be moved from the child's to the parent's account,
/// linked and a DelegatedGamePlayer Capability granted to the child through the
/// parent's ChildAccountManager to the child's ChildAccountTag.
///
/// NOTE: Assumes that the child account has a GamePlayer & ChildAccountTag configured
/// and the parent account does not have a GamePlayer stored 
///
transaction {

    let authAccountCap: Capability<&AuthAccount>
    let managerRef: &ChildAccount.ChildAccountManager
    let info: ChildAccount.ChildAccountInfo

    prepare(parent: AuthAccount, child: AuthAccount) {
        
        /* --- Configure parent's ChildAccountManager --- */
        //
        // Get ChildAccountManager Capability, linking if necessary
        if parent.borrow<&ChildAccount.ChildAccountManager>(from: ChildAccount.ChildAccountManagerStoragePath) == nil {
            // Save
            parent.save(<-ChildAccount.createChildAccountManager(), to: ChildAccount.ChildAccountManagerStoragePath)
        }
        // Ensure ChildAccountManagerViewer is linked properly
        if !parent.getCapability<&{ChildAccount.ChildAccountManagerViewer}>(ChildAccount.ChildAccountManagerPublicPath).check() {
            // Link
            parent.link<
                &{ChildAccount.ChildAccountManagerViewer}
            >(
                ChildAccount.ChildAccountManagerPublicPath,
                target: ChildAccount.ChildAccountManagerStoragePath
            )
        }
        // Get a reference to the ChildAccountManager resource
        self.managerRef = parent
            .borrow<
                &ChildAccount.ChildAccountManager
            >(
                from: ChildAccount.ChildAccountManagerStoragePath
            )!

        /* --- Link the child account's AuthAccount Capability & assign --- */
        //
        // Get the AuthAccount Capability, linking if necessary
        if !child.getCapability<&AuthAccount>(ChildAccount.AuthAccountCapabilityPath).check() {
            // Unlink any Capability that may be there
            child.unlink(ChildAccount.AuthAccountCapabilityPath)
            // Link & assign the AuthAccount Capability
            self.authAccountCap = child.linkAccount(ChildAccount.AuthAccountCapabilityPath)!
        } else {
            // Assign the AuthAccount Capability
            self.authAccountCap = child.getCapability<&AuthAccount>(ChildAccount.AuthAccountCapabilityPath)
        }

        // Get the child account's Metadata which should have been configured on creation in context of this dapp
        let childTagRef = child.borrow<
                &ChildAccount.ChildAccountTag
            >(
                from: ChildAccount.ChildAccountTagStoragePath
            ) ?? panic("Could not borrow reference to ChildAccountTag in account ".concat(child.address.toString()))
        self.info = childTagRef.info
        
        /* --- Configure parent's MonsterMaker.Collection --- */
        //
        // Check for Collection in parent's account
        if parent.borrow<&MonsterMaker.Collection>(from: MonsterMaker.CollectionStoragePath) == nil {
            // Create a new empty collection & save it to parent account
            parent.save(<-MonsterMaker.createEmptyCollection(), to: MonsterMaker.CollectionStoragePath)
        }
        // Check public capabilities on the parent's collection
        if !parent.getCapability<
                &MonsterMaker.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MonsterMaker.MonsterMakerCollectionPublic, MetadataViews.ResolverCollection}
            >(
                MonsterMaker.CollectionPublicPath
            ).check() {
            // create a public capability for the collection
            parent.unlink(MonsterMaker.CollectionPublicPath)
            parent.link<
                &MonsterMaker.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MonsterMaker.MonsterMakerCollectionPublic, MetadataViews.ResolverCollection}
            >(
                MonsterMaker.CollectionPublicPath,
                target: MonsterMaker.CollectionStoragePath
            )
        }
        // Check public capabilities on the parent's collection
        if !parent.getCapability<&MonsterMaker.Collection{NonFungibleToken.Provider}>(MonsterMaker.ProviderPrivatePath).check() {
            // Link the Provider Capability in private storage
            parent.unlink(MonsterMaker.ProviderPrivatePath)
            parent.link<&{
                NonFungibleToken.Provider
            }>(
                MonsterMaker.ProviderPrivatePath,
                target: MonsterMaker.CollectionStoragePath
            )
        }

        /* --- Configure parent's account with TicketTokens Vault --- */
        //
        if parent.borrow<&TicketToken.Vault>(from: TicketToken.VaultStoragePath) == nil {
            // Create a new flowToken Vault and put it in storage
            parent.save(<-TicketToken.createEmptyVault(), to: TicketToken.VaultStoragePath)
        }

        if !parent.getCapability<&TicketToken.Vault{FungibleToken.Receiver, FungibleToken.Balance}>(
            TicketToken.ReceiverPublicPath
        ).check() {
            // Unlink any capability that may exist there
            parent.unlink(TicketToken.ReceiverPublicPath)
            // Create a public capability to the Vault that only exposes the deposit function
            // & balance field through the Receiver & Balance interface
            parent.link<&TicketToken.Vault{FungibleToken.Receiver, FungibleToken.Balance}>(
                TicketToken.ReceiverPublicPath,
                target: TicketToken.VaultStoragePath
            )
        }

        if !parent.getCapability<&TicketToken.Vault{FungibleToken.Receiver, FungibleToken.Balance}>(
            TicketToken.ProviderPrivatePath
        ).check() {
            // Unlink any capability that may exist there
            parent.unlink(TicketToken.ProviderPrivatePath)
            // Create a private capability to the Vault that only exposes the withdraw function
            // through the Provider interface
            parent.link<&TicketToken.Vault{FungibleToken.Provider}>(
                TicketToken.ProviderPrivatePath,
                target: TicketToken.VaultStoragePath
            )
        }
    }

    execute {
        // Add child account if it's parent-child accounts aren't already linked
        let childAddress = self.authAccountCap.borrow()!.address
        if !self.managerRef.getChildAccountAddresses().contains(childAddress) {
            // Add the child account
            self.managerRef.addAsChildAccount(childAccountCap: self.authAccountCap, childAccountInfo: self.info)
        }
    }
}
`

export default ADD_AS_CHILD_MULTISIG
