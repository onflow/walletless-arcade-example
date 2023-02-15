import FungibleToken from "../../contracts/utility/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import MetadataViews from "../../contracts/utility/MetadataViews.cdc"
import GamePieceNFT from "../../contracts/GamePieceNFT.cdc"
import RockPaperScissorsGame from "../../contracts/RockPaperScissorsGame.cdc"
import ChildAccount from "../../contracts/ChildAccount.cdc"
import TicketToken from "../../contracts/TicketToken.cdc"

// TODO: Update summary comment
/// This transaction sets a user's main account up with the following
///   - GamePieceNFT.Collection
///   - ChildAccount.ChildAccountManager with ChildAccountController for new child account
/// And configures the new account with resources & Capabilities to play RockPaperScissorsGame Matches
/// This transaction assumes that the child accounts has already been created & has published 
/// a Capability to its AuthAccount in a separate transaction.
///
/// Note: A "child account" is an account that has delegated a Capability on its AuthAccount to another
/// account, making the receiving account its "parent". 
/// This relationship is represented on-chain via the ChildAccountManager.childAccounts mapping. Know that
/// the private key to this child account is generated outside of the context of this transaction and that
/// any assets in child accounts should be considered at risk if any party other than the parent has 
/// access to the given public key's paired private key. In the context of this repo, child accounts
/// are used by local game clients to facilitate a gameplay UX that does not require user transactions
/// at every step while still giving true ownership over game assets to the player. This setup is otherwise known as
/// a Hybrid Account construction - combining the benefits of app & non-custodial accounts.
/// While this approach does compromise on security, convenience is far improved. Given this security risk, only
/// trusted game clients should be used & users should consider moving very valuable assets to their parent account.
///
transaction(
        pubKey: String,
        fundingAmt: UFix64,
        childAccountName: String,
        childAccountDescription: String,
        clientIconURL: String,
        clientExternalURL: String,
        monsterBackground: Int,
        monsterHead: Int,
        monsterTorso: Int,
        monsterLeg: Int
    ) {

    let minterRef: &GamePieceNFT.Minter
    let collectionRef: &GamePieceNFT.Collection{NonFungibleToken.CollectionPublic}
    let managerRef: &ChildAccount.ChildAccountManager
    let childAccountCap: Capability<&AuthAccount>
    let info: ChildAccount.ChildAccountInfo

    prepare(parent: AuthAccount, client: AuthAccount) {
        /* --- Create a new account --- */
        //
        // Get a reference to the client's ChildAccountCreator
        let creatorRef = client.borrow<
                &ChildAccount.ChildAccountCreator
            >(
                from: ChildAccount.ChildAccountCreatorStoragePath
            ) ?? panic(
                "No ChildAccountCreator in client's account at "
                .concat(ChildAccount.ChildAccountCreatorStoragePath.toString())
            )
        // Construct the ChildAccountInfo metadata struct
        self.info = ChildAccount.ChildAccountInfo(
                name: childAccountName,
                description: childAccountDescription,
                clientIconURL: MetadataViews.HTTPFile(url: clientIconURL),
                clienExternalURL: MetadataViews.ExternalURL(clientExternalURL),
                originatingPublicKey: pubKey
            )
        // Create the account
        let child = creatorRef.createChildAccount(
            signer: client,
            initialFundingAmount: fundingAmt,
            childAccountInfo: self.info
        )
        // Link AuthAccountCapability & assign
        self.childAccountCap = child.linkAccount(
                ChildAccount.AuthAccountCapabilityPath
            ) ?? panic("Problem linking AuthAccount Capability for ".concat(child.address.toString()))

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
        child.link<
            &GamePieceNFT.Collection{NonFungibleToken.Provider}
        >(
            GamePieceNFT.ProviderPrivatePath,
            target: GamePieceNFT.CollectionStoragePath
        )
        // Grab Collection related references & Capabilities
        self.collectionRef = child.borrow<
                &GamePieceNFT.Collection{NonFungibleToken.CollectionPublic}
            >(
                from: GamePieceNFT.CollectionStoragePath
            )!
        
        /* --- Make sure child account has a GamePieceNFT.NFT to play with --- */
        //
        // Borrow a reference to the Minter Capability in minter account's storage
        self.minterRef = signer.borrow<
                &GamePieceNFT.Minter
            >(
                from: GamePieceNFT.MinterStoragePath
            ) ?? panic("Couldn't borrow reference to Minter Capability in storage at ".concat(GamePieceNFT.MinterStoragePath.toString()))

        /* --- Set user up with GamePlayer in child account --- */
        //
        // Create GamePlayer resource
        let gamePlayer <- RockPaperScissorsGame.createGamePlayer()
        // Save it
        child.save(<-gamePlayer, to: RockPaperScissorsGame.GamePlayerStoragePath)
        // Link GamePlayerPublic Capability so player can be added to Matches
        child.link<&{
            RockPaperScissorsGame.GamePlayerPublic
        }>(
            RockPaperScissorsGame.GamePlayerPublicPath,
            target: RockPaperScissorsGame.GamePlayerStoragePath
        )
        // Link GamePlayerID & DelegatedGamePlayer Capability
        child.link<&{
            RockPaperScissorsGame.DelegatedGamePlayer,
            RockPaperScissorsGame.GamePlayerID
        }>(
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

        /** --- Set user up with ChildAccountManager --- */
        //
        // Check if ChildAccountManager already exists
        if parent.borrow<&ChildAccount.ChildAccountManager>(from: ChildAccount.ChildAccountManagerStoragePath) == nil {
            // Create and save the ChildAccountManager resource
            parent.save(<-ChildAccount.createChildAccountManager(), to: ChildAccount.ChildAccountManagerStoragePath)
        }
        if !parent.getCapability<&{ChildAccount.ChildAccountManagerViewer}>(ChildAccount.ChildAccountManagerPublicPath).check() {
            parent.link<
                &{ChildAccount.ChildAccountManagerViewer}
            >(
                ChildAccount.ChildAccountManagerPublicPath,
                target: ChildAccount.ChildAccountManagerStoragePath
            )
        }
        // Assign managerRef
        self.managerRef = parent
            .borrow<
                &ChildAccount.ChildAccountManager
            >(
                from: ChildAccount.ChildAccountManagerStoragePath
            ) ?? panic("Couldn't get a reference to the parent's ChildAccountManager")
    }

    execute {
        // Build the MonsterComponent struct from given arguments
        let componentValue = GamePieceNFT.MonsterComponent(
                background: monsterBackground,
                head: monsterHead,
                torso: monsterTorso,
                leg: monsterLeg
            )
        // Mint NFT to child account's Collection
        self.minterRef.mintNFT(
            recipient: self.collectionRef,
            component: componentValue
        )
        // Add the child account to the ChildAccountManager so its AuthAccountCapability can be maintained
        self.managerRef.addAsChildAccount(childAccountCap: self.childAccountCap, childAccountInfo: self.info)
    }
}
 