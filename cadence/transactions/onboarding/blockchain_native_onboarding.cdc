#allowAccountLinking

import "FungibleToken"
import "NonFungibleToken"
import "FlowToken"
import "MetadataViews"

import "HybridCustody"
import "CapabilityFactory"
import "CapabilityFilter"
import "CapabilityDelegator"

import "GamePieceNFT"
import "RockPaperScissorsGame"
import "TicketToken"

/// This transaction creates a new account, funding creation with the signed app account and configuring it with a
/// GamePieceNFT Collection & NFT, RockPaperScissorsGame GamePlayer, and TicketToken Vault. The parent account is
/// configured with a GamePieceNFT Collection, TicketToken Vault, and HybridCustody.Manager. Lastly, the new 
/// account is then linked to the signing parent account, establishing it as a linked account of the parent account.
///
transaction(
        pubKey: String,
        fundingAmt: UFix64,
        factoryAddress: Address,
        filterAddress: Address,
        minterAddress: Address
    ) {

    let childAddress: Address
    let gamePieceCollectionRef: &GamePieceNFT.Collection{NonFungibleToken.CollectionPublic}
    let ownedAccountRef: &HybridCustody.OwnedAccount
    let managerRef: &HybridCustody.Manager
    let childAccountCapability: Capability<&HybridCustody.ChildAccount{HybridCustody.AccountPrivate, HybridCustody.AccountPublic, MetadataViews.Resolver}>

    prepare(parent: AuthAccount, app: AuthAccount) {
        /* --- Account Creation --- */
        //
        // Create the child account, funding via the signing app account
        let child = AuthAccount(payer: app)
        // Create a public key for the child account from string value in the provided arg
        // **NOTE:** You may want to specify a different signature algo for your use case
        let key = PublicKey(
            publicKey: pubKey.decodeHex(),
            signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
        )
        // Add the key to the new account
        // **NOTE:** You may want to specify a different hash algo & weight best for your use case
        child.keys.add(
            publicKey: key,
            hashAlgorithm: HashAlgorithm.SHA3_256,
            weight: 1000.0
        )
        self.childAddress = child.address

        /* --- (Optional) Additional Account Funding --- */
        //
        // Fund the new account if specified
        if fundingAmt > 0.0 {
            // Get a vault to fund the new account
            let fundingProvider = app.borrow<&FlowToken.Vault{FungibleToken.Provider}>(from: /storage/flowTokenVault)!
            // Fund the new account with the initialFundingAmount specified
            child.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow()!
                .deposit(from: <-fundingProvider.withdraw(amount: fundingAmt))
        }

        /* --- Set up GamePieceNFT.Collection --- */
        //
        // Create a new empty collection & save it to the child account
        child.save(<-GamePieceNFT.createEmptyCollection(), to: GamePieceNFT.CollectionStoragePath)
        // create a public capability for the collection
        child.link<
            &GamePieceNFT.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, GamePieceNFT.GamePieceNFTCollectionPublic, MetadataViews.ResolverCollection}
        >(
            GamePieceNFT.CollectionPublicPath,
            target: GamePieceNFT.CollectionStoragePath
        )
        // Link the Provider Capability in private storage
        child.link<&GamePieceNFT.Collection{NonFungibleToken.Provider}>(
            GamePieceNFT.ProviderPrivatePath,
            target: GamePieceNFT.CollectionStoragePath
        )
        // Grab Collection related references & Capabilities
        self.gamePieceCollectionRef = child.borrow<&GamePieceNFT.Collection{NonFungibleToken.CollectionPublic}>(
                from: GamePieceNFT.CollectionStoragePath
            )!

        /* --- Set user up with GamePlayer in child account --- */
        //
        // Create GamePlayer resource
        let gamePlayer <- RockPaperScissorsGame.createGamePlayer()
        // Save it
        child.save(<-gamePlayer, to: RockPaperScissorsGame.GamePlayerStoragePath)
        // Link GamePlayerPublic Capability so player can be added to Matches
        child.link<&RockPaperScissorsGame.GamePlayer{RockPaperScissorsGame.GamePlayerPublic}>(
            RockPaperScissorsGame.GamePlayerPublicPath,
            target: RockPaperScissorsGame.GamePlayerStoragePath
        )
        // Link GamePlayerID & DelegatedGamePlayer Capability
        child.link<
            &RockPaperScissorsGame.GamePlayer{RockPaperScissorsGame.DelegatedGamePlayer, RockPaperScissorsGame.GamePlayerID}
        >(
            RockPaperScissorsGame.GamePlayerPrivatePath,
            target: RockPaperScissorsGame.GamePlayerStoragePath
        )

        /* --- Set child account up with TicketToken.Vault --- */
        //
        // Create & save a Vault
        child.save(<-TicketToken.createEmptyVault(), to: TicketToken.VaultStoragePath)
        // Create a public capability to the Vault that only exposes the deposit function
        // & balance field through the Receiver & Balance interface
        child.link<&TicketToken.Vault{FungibleToken.Receiver, FungibleToken.Balance, MetadataViews.Resolver}>(
            TicketToken.ReceiverPublicPath,
            target: TicketToken.VaultStoragePath
        )
        // Create a private capability to the Vault that only exposes the withdraw function
        // through the Provider interface
        child.link<&TicketToken.Vault{FungibleToken.Provider}>(
            TicketToken.ProviderPrivatePath,
            target: TicketToken.VaultStoragePath
        )

        /* --- Configure OwnedAccount in child account --- */
        //
        var acctCap = child.linkAccount(HybridCustody.LinkedAccountPrivatePath)
            ?? panic("problem linking account Capability for new account")
        
        // Create an OwnedAccount & link Capabilities
        let ownedAccount <- HybridCustody.createOwnedAccount(acct: acctCap)
        child.save(<-ownedAccount, to: HybridCustody.OwnedAccountStoragePath)
        child
            .link<&HybridCustody.OwnedAccount{HybridCustody.BorrowableAccount, HybridCustody.OwnedAccountPublic, MetadataViews.Resolver}>(
                HybridCustody.OwnedAccountPrivatePath,
                target: HybridCustody.OwnedAccountStoragePath
            )
        child
            .link<&HybridCustody.OwnedAccount{HybridCustody.OwnedAccountPublic, MetadataViews.Resolver}>(
                HybridCustody.OwnedAccountPublicPath, 
                target: HybridCustody.OwnedAccountStoragePath
            )
        // Get a reference to the OwnedAccount resource
        self.ownedAccountRef = child.borrow<&HybridCustody.OwnedAccount>(from: HybridCustody.OwnedAccountStoragePath)!

        // Get the CapabilityFactory.Manager Capability
        let factory = getAccount(factoryAddress)
            .getCapability<&CapabilityFactory.Manager{CapabilityFactory.Getter}>(
                CapabilityFactory.PublicPath
            )
        assert(factory.check(), message: "factory address is not configured properly")

        // Get the CapabilityFilter.Filter Capability
        let filter = getAccount(filterAddress).getCapability<&{CapabilityFilter.Filter}>(CapabilityFilter.PublicPath)
        assert(filter.check(), message: "capability filter is not configured properly")

        // Configure access for the delegatee parent account
        self.ownedAccountRef.publishToParent(parentAddress: parent.address, factory: factory, filter: filter)

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
            >(GamePieceNFT.CollectionPublicPath).check() {
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
            parent.link<&GamePieceNFT.Collection{NonFungibleToken.Provider}>(
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

        /* --- Configure HybridCustody Manager --- */
        //
        // Configure HybridCustody.Manager if needed
        if parent.borrow<&HybridCustody.Manager>(from: HybridCustody.ManagerStoragePath) == nil {
            let m <- HybridCustody.createManager(filter: filter)
            parent.save(<- m, to: HybridCustody.ManagerStoragePath)
        }

        // Link Capabilities
        parent.unlink(HybridCustody.ManagerPublicPath)
        parent.unlink(HybridCustody.ManagerPrivatePath)
        parent.link<&HybridCustody.Manager{HybridCustody.ManagerPrivate, HybridCustody.ManagerPublic}>(
            HybridCustody.ManagerPrivatePath,
            target: HybridCustody.ManagerStoragePath
        )
        parent.link<&HybridCustody.Manager{HybridCustody.ManagerPublic}>(
            HybridCustody.ManagerPublicPath,
            target: HybridCustody.ManagerStoragePath
        )

        // Get a reference to the Manager and add the account
        self.managerRef = parent.borrow<&HybridCustody.Manager>(from: HybridCustody.ManagerStoragePath)
            ?? panic("manager no found")
        // Claim the ChildAccount Capability published earlier in the transaction by the OwnedAccount
        let inboxName = HybridCustody.getChildAccountIdentifier(parent.address)
        self.childAccountCapability = parent
            .inbox
            .claim<&HybridCustody.ChildAccount{HybridCustody.AccountPrivate, HybridCustody.AccountPublic, MetadataViews.Resolver}>(
                inboxName,
                provider: child.address
            ) ?? panic("child account cap not found")
    }

    execute {
        // Borrow a reference to the MinterPublic
        let minterPublicRef = getAccount(minterAddress).getCapability<&GamePieceNFT.Minter{GamePieceNFT.MinterPublic}>(
                GamePieceNFT.MinterPublicPath
            ).borrow()
            ?? panic("Couldn't borrow reference to MinterPublic at ".concat(minterAddress.toString()))
        // Mint NFT to child account's Collection
        minterPublicRef.mintNFT(
            recipient: self.gamePieceCollectionRef,
            component: GamePieceNFT.getRandomComponent()
        )
        // Construct the Display from the game contract info
        let info = RockPaperScissorsGame.info
        let display = MetadataViews.Display(
            name: info.name,
            description: info.description,
            thumbnail: info.thumbnail
        )
        // Add the child account to the HybridCustody.Manager so its AuthAccountCapability can be maintained
        self.managerRef.addAccount(cap: self.childAccountCapability)
        self.managerRef.setChildAccountDisplay(address: self.childAddress, display)
        // Finally, set the owner display as well
        self.ownedAccountRef.setDisplay(display)
    }
}
 