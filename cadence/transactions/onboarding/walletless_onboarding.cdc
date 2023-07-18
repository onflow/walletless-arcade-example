import "MetadataViews"
import "FungibleToken"
import "NonFungibleToken"
import "GamePieceNFT"
import "RockPaperScissorsGame"
import "TicketToken"

/// This transaction creates a signer-funded account, adding the given public key. The new account is additionally funded
/// with specified amount of Flow from the signer's account. The newly created account is then configured with resources
/// & Capabilities necessary to play RockPaperScissorsGame Matches.
///
transaction(
        pubKey: String,
        fundingAmt: UFix64,
        monsterBackground: Int,
        monsterHead: Int,
        monsterTorso: Int,
        monsterLeg: Int
    ) {

    prepare(signer: AuthAccount) {
        /* --- Create a new account --- */
        //
        // Create the new account
        let newAccount = AuthAccount(payer: signer)
        // Create a public key for the proxy account from the passed in string
        let key = PublicKey(
                publicKey: pubKey.decodeHex(),
                signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
            )
        // Add the given key to the new account
        newAccount.keys.add(
            publicKey: key,
            hashAlgorithm: HashAlgorithm.SHA3_256,
            weight: 1000.0
        )
        // Fund the account if so specified
        if fundingAmt > 0.0 {
            // Add some initial funds to the new account, pulled from the signing account.  Amount determined by initialFundingAmount
            let fundingVault <- signer.borrow<&{FungibleToken.Provider}>(
                    from: /storage/flowTokenVault
                )!.withdraw(
                    amount: fundingAmt
                )
            newAccount.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow()!.deposit(
                from: <- fundingVault
            )
        }

        /* --- Set up GamePieceNFT.Collection --- */
        //
        // create & save it to the account
        newAccount.save(<-GamePieceNFT.createEmptyCollection(), to: GamePieceNFT.CollectionStoragePath)

        // create a public capability for the collection
        newAccount.link<
            &GamePieceNFT.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, GamePieceNFT.GamePieceNFTCollectionPublic, MetadataViews.ResolverCollection}
        >(
            GamePieceNFT.CollectionPublicPath,
            target: GamePieceNFT.CollectionStoragePath
        )

        // Link the Provider Capability in private storage
        newAccount.link<&GamePieceNFT.Collection{NonFungibleToken.Provider}>(
            GamePieceNFT.ProviderPrivatePath,
            target: GamePieceNFT.CollectionStoragePath
        )

        // Grab Collection related references & Capabilities
        let collectionRef = newAccount
            .borrow<&GamePieceNFT.Collection{NonFungibleToken.CollectionPublic}>(
                from: GamePieceNFT.CollectionStoragePath
            )!
        
        /* --- Make sure new account has a GamePieceNFT.NFT to play with --- */
        //
        // Borrow a reference to the Minter Capability in minter account's storage
        let minterRef = signer.borrow<&GamePieceNFT.Minter>(from: GamePieceNFT.MinterStoragePath)
            ?? panic("Couldn't borrow reference to Minter Capability in storage at ".concat(GamePieceNFT.MinterStoragePath.toString()))
        // Build the MonsterComponent struct from given arguments
        let componentValue = GamePieceNFT.MonsterComponent(
                background: monsterBackground,
                head: monsterHead,
                torso: monsterTorso,
                leg: monsterLeg
            )
        // Mint the NFT to the new account's collection
        minterRef.mintNFT(recipient: collectionRef, component: componentValue)

        /* --- Set user up with GamePlayer in new account --- */
        //
        // Create GamePlayer resource
        let gamePlayer <- RockPaperScissorsGame.createGamePlayer()
        // Save it
        newAccount.save(<-gamePlayer, to: RockPaperScissorsGame.GamePlayerStoragePath)
        // Link GamePlayerPublic Capability so player can be added to Matches
        newAccount.link<&{RockPaperScissorsGame.GamePlayerPublic}>(
            RockPaperScissorsGame.GamePlayerPublicPath,
            target: RockPaperScissorsGame.GamePlayerStoragePath
        )
        // Link GamePlayerID Capability
        newAccount.link<&{RockPaperScissorsGame.DelegatedGamePlayer, RockPaperScissorsGame.GamePlayerID}>(
            RockPaperScissorsGame.GamePlayerPrivatePath,
            target: RockPaperScissorsGame.GamePlayerStoragePath
        )

        /* --- Set user up with TicketToken.Vault --- */
        //
        // Create & save a Vault
        newAccount.save(<-TicketToken.createEmptyVault(), to: TicketToken.VaultStoragePath)
        // Create a public capability to the Vault that only exposes the deposit function
        // & balance field through the Receiver & Balance interface
        newAccount.link<&TicketToken.Vault{FungibleToken.Receiver, FungibleToken.Balance, MetadataViews.Resolver}>(
            TicketToken.ReceiverPublicPath,
            target: TicketToken.VaultStoragePath
        )
        // Create a private capability to the Vault that only exposes the withdraw function
        // through the Provider interface
        newAccount.link<&TicketToken.Vault{FungibleToken.Provider}>(
            TicketToken.ProviderPrivatePath,
            target: TicketToken.VaultStoragePath
        )
    }
}