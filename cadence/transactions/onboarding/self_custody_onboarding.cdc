import "FungibleToken"
import "NonFungibleToken"
import "MetadataViews"
import "GamePieceNFT"
import "RockPaperScissorsGame"
import "TicketToken"

/// This transaction sets up the following in a signer's account
/// - GamePieceNFT.Collection
/// - GamePieceNFT.NFT
/// - RockPaperScissorsGame.GamePlayer
/// - TicketToken.Vault
///
/// Should be run before an account interacts with RockPaperScissorsGame
///
transaction(minterAddress: Address) {

    // local variable for storing the minter reference
    let minterPublicRef: &GamePieceNFT.Minter{GamePieceNFT.MinterPublic}
    /// Reference to the receiver's collection
    let collectionRef: &GamePieceNFT.Collection{NonFungibleToken.CollectionPublic}

    prepare(signer: AuthAccount) {
        
        /** --- Setup signer's GamePieceNFT.Collection --- */
        //
        // Set up GamePieceNFT.Collection if it doesn't exist
        if signer.borrow<&GamePieceNFT.Collection>(from: GamePieceNFT.CollectionStoragePath) == nil {
            // Create a new empty collection
            let collection <- GamePieceNFT.createEmptyCollection()
            // save it to the account
            signer.save(<-collection, to: GamePieceNFT.CollectionStoragePath)
        }
        // Check for public capabilities
        if !signer.getCapability<
                &GamePieceNFT.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, GamePieceNFT.GamePieceNFTCollectionPublic, MetadataViews.ResolverCollection}
            >(
                GamePieceNFT.CollectionPublicPath
            ).check() {
            // create a public capability for the collection
            signer.unlink(GamePieceNFT.CollectionPublicPath)
            signer.link<
                &GamePieceNFT.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, GamePieceNFT.GamePieceNFTCollectionPublic, MetadataViews.ResolverCollection}
            >(
                GamePieceNFT.CollectionPublicPath,
                target: GamePieceNFT.CollectionStoragePath
            )
        }
        // Check for private capabilities
        if !signer.getCapability<&GamePieceNFT.Collection{NonFungibleToken.Provider}>(GamePieceNFT.ProviderPrivatePath).check() {
            // Link the Provider Capability in private storage
            signer.unlink(GamePieceNFT.ProviderPrivatePath)
            signer.link<
                &GamePieceNFT.Collection{NonFungibleToken.Provider}
            >(
                GamePieceNFT.ProviderPrivatePath,
                target: GamePieceNFT.CollectionStoragePath
            )
        }
        // Grab Collection related references & Capabilities
        self.collectionRef = signer.borrow<&GamePieceNFT.Collection{NonFungibleToken.CollectionPublic}>(
                from: GamePieceNFT.CollectionStoragePath
            ) ?? panic("Could not borrow reference to signer's CollectionPublic!")
        
        // Borrow a reference to the MinterPublic
        self.minterPublicRef = getAccount(minterAddress).getCapability<&GamePieceNFT.Minter{GamePieceNFT.MinterPublic}>(
                GamePieceNFT.MinterPublicPath
            ).borrow()
            ?? panic("Couldn't borrow reference to MinterPublic at ".concat(minterAddress.toString()))

        /** --- Set user up with GamePlayer --- */
        //
        // Check if a GamePlayer already exists, pass this block if it does
        if signer.borrow<&RockPaperScissorsGame.GamePlayer>(from: RockPaperScissorsGame.GamePlayerStoragePath) == nil {
            // Create GamePlayer resource
            let gamePlayer <- RockPaperScissorsGame.createGamePlayer()
            // Save it
            signer.save(<-gamePlayer, to: RockPaperScissorsGame.GamePlayerStoragePath)
        }
        if !signer.getCapability<&{RockPaperScissorsGame.GamePlayerPublic}>(RockPaperScissorsGame.GamePlayerPublicPath).check() {
            // Link GamePlayerPublic Capability so player can be added to Matches
            signer.link<
                &{RockPaperScissorsGame.GamePlayerPublic}
            >(
                RockPaperScissorsGame.GamePlayerPublicPath,
                target: RockPaperScissorsGame.GamePlayerStoragePath
            )
        }
        if !signer.getCapability<&{RockPaperScissorsGame.GamePlayerID, RockPaperScissorsGame.DelegatedGamePlayer}>(
                RockPaperScissorsGame.GamePlayerPrivatePath
            ).check() {
            // Link DelegatedGamePlayer & GamePlayerID Capability
            signer.link<
                &{RockPaperScissorsGame.DelegatedGamePlayer,RockPaperScissorsGame.GamePlayerID}
            >(
                RockPaperScissorsGame.GamePlayerPrivatePath,
                target: RockPaperScissorsGame.GamePlayerStoragePath
            )
        }

        /* --- Set signer's account up with TicketToken.Vault --- */
        //
        // Create & save a Vault
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
        if !signer.getCapability<&TicketToken.Vault{FungibleToken.Provider}>(TicketToken.ProviderPrivatePath).check() {
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

    execute {
        /** --- Make sure signer has a GamePieceNFT.NFT to play with --- */
        //
        // Mint GamePieceNFT.NFT if one doesn't exist
        if self.collectionRef.getIDs().length == 0 {
            // mint the NFT and deposit it to the recipient's collection
            self.minterPublicRef.mintNFT(
                recipient: self.collectionRef,
                component: GamePieceNFT.getRandomComponent()
            )
        }
    }
}
