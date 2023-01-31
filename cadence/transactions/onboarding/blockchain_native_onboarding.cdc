import FungibleToken from "../../contracts/utility/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import MetadataViews from "../../contracts/utility/MetadataViews.cdc"
import MonsterMaker from "../../contracts/MonsterMaker.cdc"
import RockPaperScissorsGame from "../../contracts/RockPaperScissorsGame.cdc"
import ChildAccount from "../../contracts/ChildAccount.cdc"
import TicketToken from "../../contracts/TicketToken.cdc"

// TODO: Update summary comment
/// This transaction sets a user's main account up with the following
///   - MonsterMaker.Collection
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

    let minterRef: &MonsterMaker.NFTMinter
    let collectionRef: &MonsterMaker.Collection
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

        /* --- Set up MonsterMaker.Collection --- */
        //
        // Create a new empty collection & save it to the child account
        child.save(<-MonsterMaker.createEmptyCollection(), to: MonsterMaker.CollectionStoragePath)
        // create a public capability for the collection
        child.link<&{
            NonFungibleToken.Receiver,
            NonFungibleToken.CollectionPublic,
            MonsterMaker.MonsterMakerCollectionPublic,
            MetadataViews.ResolverCollection
        }>(
            MonsterMaker.CollectionPublicPath,
            target: MonsterMaker.CollectionStoragePath
        )
        // Link the Provider Capability in private storage
        child.link<&{
            NonFungibleToken.Provider
        }>(
            MonsterMaker.ProviderPrivatePath,
            target: MonsterMaker.CollectionStoragePath
        )
        // Grab Collection related references & Capabilities
        self.collectionRef = child.borrow<&MonsterMaker.Collection>(from: MonsterMaker.CollectionStoragePath)!
        
        /* --- Make sure child account has a MonsterMaker.NFT to play with --- */
        //
        // Borrow a reference to the NFTMinter Capability in minter account's storage
        // NOTE: This assumes a Capability is stored, and not the base resource - this would occurr
        // if the signing minter was granted the NFTMinter Capability for a base resource located in
        // another account
        let minterCapRef = client.borrow<
                &Capability<&MonsterMaker.NFTMinter>
            >(
                from: MonsterMaker.MinterStoragePath
            ) ?? panic("Couldn't borrow reference to NFTMinter Capability in storage at ".concat(MonsterMaker.MinterStoragePath.toString()))
        self.minterRef = minterCapRef.borrow() ?? panic("Couldn't borrow reference to NFTMinter from Capability")

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
        // Link GamePlayerID Capability
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

        /** --- Setup parent's MonsterMaker.Collection --- */
        //
        // Set up MonsterMaker.Collection if it doesn't exist
        if parent.borrow<&MonsterMaker.Collection>(from: MonsterMaker.CollectionStoragePath) == nil {
            // Create a new empty collection
            let collection <- MonsterMaker.createEmptyCollection()
            // save it to the account
            parent.save(<-collection, to: MonsterMaker.CollectionStoragePath)
        }
        // Check for public capabilities
        if !parent.getCapability<&{
                NonFungibleToken.Receiver,
                NonFungibleToken.CollectionPublic,
                MonsterMaker.MonsterMakerCollectionPublic,
                MetadataViews.ResolverCollection
            }>(
                MonsterMaker.CollectionPublicPath
            ).check() {
            // create a public capability for the collection
            parent.link<&{
                NonFungibleToken.Receiver,
                NonFungibleToken.CollectionPublic,
                MonsterMaker.MonsterMakerCollectionPublic,
                MetadataViews.ResolverCollection
            }>(
                MonsterMaker.CollectionPublicPath,
                target: MonsterMaker.CollectionStoragePath
            )
        }
        // Check for private capabilities
        if !parent.getCapability<&{NonFungibleToken.Provider}>(MonsterMaker.ProviderPrivatePath).check() {
            // Link the Provider Capability in private storage
            parent.link<&{
                NonFungibleToken.Provider
            }>(
                MonsterMaker.ProviderPrivatePath,
                target: MonsterMaker.CollectionStoragePath
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
        let componentValue = MonsterMaker.MonsterComponent(
                background: monsterBackground,
                head: monsterHead,
                torso: monsterTorso,
                leg: monsterLeg
            )
        // TODO: Add royalty feature to MM using beneficiaries, cuts, and descriptions. At the moment, we don't provide royalties with KI, so this will be an empty list.
        let royalties: [MetadataViews.Royalty] = []
        // Mint NFT to child account's Collection
        self.minterRef.mintNFT(
            recipient: self.collectionRef,
            component: componentValue,
            royalties: royalties
        )
        // Add the child account to the ChildAccountManager so its AuthAccountCapability can be maintained
        self.managerRef.addAsChildAccount(childAccountCap: self.childAccountCap, childAccountInfo: self.info)
    }
}
 