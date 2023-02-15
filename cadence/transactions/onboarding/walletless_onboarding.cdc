import ChildAccount from "../../contracts/ChildAccount.cdc"
import MetadataViews from "../../contracts/utility/MetadataViews.cdc"
import FungibleToken from "../../contracts/utility/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import GamePieceNFT from "../../contracts/GamePieceNFT.cdc"
import RockPaperScissorsGame from "../../contracts/RockPaperScissorsGame.cdc"
import TicketToken from "../../contracts/TicketToken.cdc"

/// This transaction creates an account from the given public key, using the
/// ChildAccountCreator with the signer as the account's payer, additionally
/// funding the new account with the specified amount of Flow from the signer's
/// account. The newly created account is then configured with resources &
/// Capabilities necessary to play RockPaperScissorsGame Matches.
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

    prepare(signer: AuthAccount) {
        /* --- Create a new account --- */
        //
        // Get a reference to the signer's ChildAccountCreator
        let creatorRef = signer.borrow<
                &ChildAccount.ChildAccountCreator
            >(
                from: ChildAccount.ChildAccountCreatorStoragePath
            ) ?? panic(
                "No ChildAccountCreator in signer's account at "
                .concat(ChildAccount.ChildAccountCreatorStoragePath.toString())
            )
        // Construct the ChildAccountInfo metadata struct
        let info = ChildAccount.ChildAccountInfo(
                name: childAccountName,
                description: childAccountDescription,
                clientIconURL: MetadataViews.HTTPFile(url: clientIconURL),
                clienExternalURL: MetadataViews.ExternalURL(clientExternalURL),
                originatingPublicKey: pubKey
            )
        // Create the account
        let newAccount = creatorRef.createChildAccount(
            signer: signer,
            initialFundingAmount: fundingAmt,
            childAccountInfo: info
        )

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
        newAccount.link<
            &GamePieceNFT.Collection{NonFungibleToken.Provider}
        >(
            GamePieceNFT.ProviderPrivatePath,
            target: GamePieceNFT.CollectionStoragePath
        )

        // Grab Collection related references & Capabilities
        let collectionRef = newAccount.borrow<
                &GamePieceNFT.Collection{NonFungibleToken.CollectionPublic}
            >(
                from: GamePieceNFT.CollectionStoragePath
            )!
        
        /* --- Make sure new account has a GamePieceNFT.NFT to play with --- */
        //
        // Borrow a reference to the Minter Capability in minter account's storage
        let minterRef = signer.borrow<
                &GamePieceNFT.Minter
            >(
                from: GamePieceNFT.MinterStoragePath
            ) ?? panic("Couldn't borrow reference to Minter Capability in storage at ".concat(GamePieceNFT.MinterStoragePath.toString()))
        // Build the MonsterComponent struct from given arguments
        let componentValue = GamePieceNFT.MonsterComponent(
                background: monsterBackground,
                head: monsterHead,
                torso: monsterTorso,
                leg: monsterLeg
            )
        // Mint the NFT to the new account's collection
        minterRef.mintNFT(
            recipient: collectionRef,
            component: componentValue
        )

        /* --- Set user up with GamePlayer in new account --- */
        //
        // Create GamePlayer resource
        let gamePlayer <- RockPaperScissorsGame.createGamePlayer()
        // Save it
        newAccount.save(<-gamePlayer, to: RockPaperScissorsGame.GamePlayerStoragePath)
        // Link GamePlayerPublic Capability so player can be added to Matches
        newAccount.link<&{
            RockPaperScissorsGame.GamePlayerPublic
        }>(
            RockPaperScissorsGame.GamePlayerPublicPath,
            target: RockPaperScissorsGame.GamePlayerStoragePath
        )
        // Link GamePlayerID Capability
        newAccount.link<&{
            RockPaperScissorsGame.DelegatedGamePlayer,
            RockPaperScissorsGame.GamePlayerID
        }>(
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