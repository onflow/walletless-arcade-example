import ChildAccount from "../../contracts/ChildAccount.cdc"
import MetadataViews from "../../contracts/utility/MetadataViews.cdc"
import FungibleToken from "../../contracts/utility/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import MonsterMaker from "../../contracts/MonsterMaker.cdc"
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

        /* --- Set up MonsterMaker.Collection --- */
        //
        // create & save it to the account
        newAccount.save(<-MonsterMaker.createEmptyCollection(), to: MonsterMaker.CollectionStoragePath)

        // create a public capability for the collection
        newAccount.link<
            &MonsterMaker.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MonsterMaker.MonsterMakerCollectionPublic, MetadataViews.ResolverCollection}
        >(
            MonsterMaker.CollectionPublicPath,
            target: MonsterMaker.CollectionStoragePath
        )

        // Link the Provider Capability in private storage
        newAccount.link<
            &MonsterMaker.Collection{NonFungibleToken.Provider}
        >(
            MonsterMaker.CollectionPublicPath,
            target: MonsterMaker.CollectionStoragePath
        )

        // Grab Collection related references & Capabilities
        let collectionRef = newAccount.borrow<&MonsterMaker.Collection>(from: MonsterMaker.CollectionStoragePath)!
        
        /* --- Make sure new account has a GamePieceNFT.NFT to play with --- */
        //
        // Borrow a reference to the NFTMinter Capability in minter account's storage
        // NOTE: This assumes a Capability is stored, and not the base resource - this would occurr
        // if the signing minter was granted the NFTMinter Capability for a base resource located in
        // another account
        let minterCapRef = signer.borrow<
                &Capability<&MonsterMaker.NFTMinter>
            >(
                from: MonsterMaker.MinterStoragePath
            ) ?? panic("Couldn't borrow reference to NFTMinter Capability in storage at ".concat(MonsterMaker.MinterStoragePath.toString()))
        let minterRef = minterCapRef.borrow() ?? panic("Couldn't borrow reference to NFTMinter from Capability")
        // Build the MonsterComponent struct from given arguments
        let componentValue = MonsterMaker.MonsterComponent(
                background: monsterBackground,
                head: monsterHead,
                torso: monsterTorso,
                leg: monsterLeg
            )
        // TODO: Add royalty feature to MM using beneficiaries, cuts, and descriptions. At the moment, we don't provide royalties with KI, so this will be an empty list.
        let royalties: [MetadataViews.Royalty] = []
        // Mint the NFT to the new account's collection
        minterRef.mintNFT(
            recipient: collectionRef,
            component: componentValue,
            royalties: royalties
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