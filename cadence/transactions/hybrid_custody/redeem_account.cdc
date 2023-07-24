import "FungibleToken"
import "NonFungibleToken"
import "MetadataViews"

import "HybridCustody"

import "GamePieceNFT"
import "RockPaperScissorsGame"
import "TicketToken"

/// This transaction redeems a published
transaction(childAddress: Address) {
    prepare(parent: AuthAccount) {
        /* --- Redeem HybridCustody ChildAccount --- */
        //
        // Configure a HybridCustody Manager if needed
        if parent.borrow<&HybridCustody.Manager>(from: HybridCustody.ManagerStoragePath) == nil {
            let m <- HybridCustody.createManager(filter: nil)
            parent.save(<- m, to: HybridCustody.ManagerStoragePath)

            parent.unlink(HybridCustody.ManagerPublicPath)
            parent.unlink(HybridCustody.ManagerPrivatePath)

            parent.link<&HybridCustody.Manager{HybridCustody.ManagerPrivate, HybridCustody.ManagerPublic}>(HybridCustody.ManagerPrivatePath, target: HybridCustody.ManagerStoragePath)
            parent.link<&HybridCustody.Manager{HybridCustody.ManagerPublic}>(HybridCustody.ManagerPublicPath, target: HybridCustody.ManagerStoragePath)
        }
        // Get a reference to the Manager
        let manager = parent.borrow<&HybridCustody.Manager>(from: HybridCustody.ManagerStoragePath)
            ?? panic("Manager not found in signing account!")

        // Get the published ChildAccount Capability name & claim it
        let inboxName = HybridCustody.getChildAccountIdentifier(parent.address)
        let cap = parent.inbox.claim<&HybridCustody.ChildAccount{HybridCustody.AccountPrivate, HybridCustody.AccountPublic, MetadataViews.Resolver}>(inboxName, provider: childAddress)
            ?? panic("ChildAccount not available for claiming!")

        // Add the claimed Capability to the Manager as a child account
        manager.addAccount(cap: cap)

        // Create display from the known contract association
        let info = RockPaperScissorsGame.info
        let display = MetadataViews.Display(
                name: info.name,
                description: info.description,
                thumbnail: info.thumbnail
            )
        // Set parent-managed Display on the added account
        manager.setChildAccountDisplay(address: childAddress, display)

        /** --- Setup parent's GamePieceNFT.Collection --- */
        //
        // Set up GamePieceNFT.Collection if it doesn't exist
        if parent.borrow<&GamePieceNFT.Collection>(from: GamePieceNFT.CollectionStoragePath) == nil {
            // Create a new empty collection
            let collection <- GamePieceNFT.createEmptyCollection()
            // save it to the account
            parent.save(<-collection, to: GamePieceNFT.CollectionStoragePath)
        }
        // Check for public capabilities
        if !parent.getCapability<
                &GamePieceNFT.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, GamePieceNFT.GamePieceNFTCollectionPublic, MetadataViews.ResolverCollection}
            >(
                GamePieceNFT.CollectionPublicPath
            ).check() {
            // create a public capability for the collection
            parent.unlink(GamePieceNFT.CollectionPublicPath)
            parent.link<
                &GamePieceNFT.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, GamePieceNFT.GamePieceNFTCollectionPublic, MetadataViews.ResolverCollection}
            >(
                GamePieceNFT.CollectionPublicPath,
                target: GamePieceNFT.CollectionStoragePath
            )
        }
        // Check for private capabilities
        if !parent.getCapability<&GamePieceNFT.Collection{NonFungibleToken.Provider}>(GamePieceNFT.ProviderPrivatePath).check() {
            // Link the Provider Capability in private storage
            parent.unlink(GamePieceNFT.ProviderPrivatePath)
            parent.link<
                &GamePieceNFT.Collection{NonFungibleToken.Provider}
            >(
                GamePieceNFT.ProviderPrivatePath,
                target: GamePieceNFT.CollectionStoragePath
            )
        }

        /* --- Set parent account up with TicketToken.Vault --- */
        //
        // Create & save a Vault
        if parent.borrow<&TicketToken.Vault>(from: TicketToken.VaultStoragePath) == nil {
            // Create a new flowToken Vault and put it in storage
            parent.save(<-TicketToken.createEmptyVault(), to: TicketToken.VaultStoragePath)
        }

        if !parent.getCapability<&TicketToken.Vault{FungibleToken.Receiver, FungibleToken.Balance, MetadataViews.Resolver}>(
            TicketToken.ReceiverPublicPath
        ).check() {
            // Unlink any capability that may exist there
            parent.unlink(TicketToken.ReceiverPublicPath)
            // Create a public capability to the Vault that only exposes the deposit function
            // & balance field through the Receiver & Balance interface
            parent.link<&TicketToken.Vault{FungibleToken.Receiver, FungibleToken.Balance, MetadataViews.Resolver}>(
                TicketToken.ReceiverPublicPath,
                target: TicketToken.VaultStoragePath
            )
        }

        if !parent.getCapability<&TicketToken.Vault{FungibleToken.Provider}>(
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
}