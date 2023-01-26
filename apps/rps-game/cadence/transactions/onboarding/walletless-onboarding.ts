const WALLETLESS_ONBOARDING = `// import ChildAccount from 0xChildAccount
import ChildAccount from 0xChildAccount
import MetadataViews from 0xMetadataViews
import FungibleToken from 0xFungibleToken
import NonFungibleToken from 0xNonFungibleToken
import GamePieceNFT from 0xGamePieceNFT
import RockPaperScissorsGame from 0xRockPaperScissorsGame

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
        minterAddress: Address
    ) {

    prepare(signer: AuthAccount) {
        /* Create a new account from the given public key */
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

        /* Set up GamePieceNFT.Collection */
        //
        // Create a new empty collection
        let collection <- GamePieceNFT.createEmptyCollection()

        // save it to the account
        newAccount.save(<-collection, to: GamePieceNFT.CollectionStoragePath)

        // create a public capability for the collection
        newAccount.link<&{
            NonFungibleToken.Receiver,
            NonFungibleToken.CollectionPublic,
            GamePieceNFT.GamePieceNFTCollectionPublic,
            MetadataViews.ResolverCollection
        }>(
            GamePieceNFT.CollectionPublicPath,
            target: GamePieceNFT.CollectionStoragePath
        )

        // Link the Provider Capability in private storage
        newAccount.link<&{
            NonFungibleToken.Provider
        }>(
            GamePieceNFT.ProviderPrivatePath,
            target: GamePieceNFT.CollectionStoragePath
        )
        // Grab Collection related references & Capabilities
        let collectionRef = newAccount.borrow<&GamePieceNFT.Collection>(from: GamePieceNFT.CollectionStoragePath)!
        
        /* --- Make sure signer has a GamePieceNFT.NFT to play with --- */
        //
        // Get a reference to the MinterPublic Capability
        let minterRef = getAccount(minterAddress)
            .getCapability<
                &{GamePieceNFT.MinterPublic}
            >(
                GamePieceNFT.MinterPublicPath
            ).borrow()
            ?? panic("Could not get a reference to the MinterPublic Capability at the specified address ".concat(minterAddress.toString()))
        minterRef.mintNFT(recipient: collectionRef)

        /* --- Set user up with GamePlayer --- */
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
        signer.link<&{
            RockPaperScissorsGame.DelegatedGamePlayer,
            RockPaperScissorsGame.GamePlayerID
        }>(
            RockPaperScissorsGame.GamePlayerPrivatePath,
            target: RockPaperScissorsGame.GamePlayerStoragePath
        )
    }
}`;

export default WALLETLESS_ONBOARDING;
