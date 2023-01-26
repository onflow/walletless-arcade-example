import FungibleToken from "../../contracts/utility/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import MetadataViews from "../../contracts/utility/MetadataViews.cdc"
import GamePieceNFT from "../../contracts/GamePieceNFT.cdc"
import RockPaperScissorsGame from "../../contracts/RockPaperScissorsGame.cdc"
import ChildAccount from "../../contracts/ChildAccount.cdc"

/// This transactions sets up a user's account with:
/// - ChildAccountManager
/// - GamePieceNFT Collection
/// - GamePlayer
/// - Child account from the provided public key
/// Then the Child account is set up with
/// - ChildAccountTag with user's DelegatedGamePlayer Capability
/// - GamePieceNFT Collection & NFT
///
transaction(
        pubKey: String,
        fundingAmt: UFix64,
        childAccountName: String,
        childAccountDescription: String,
        clientIconURL: String,
        clientExternalURL: String
    ) {

    prepare(signer: AuthAccount) {

        /* --- Set up parent account with necessary resources --- */
        
        /** --- Setup signer's GamePieceNFT.Collection --- */
        //
        // Set up GamePieceNFT.Collection if it doesn't exist
        if signer.borrow<&GamePieceNFT.Collection>(from: GamePieceNFT.CollectionStoragePath) == nil {
            // Create a new empty collection
            let collection <- GamePieceNFT.createEmptyCollection()

            // save it to the account
            signer.save(<-collection, to: GamePieceNFT.CollectionStoragePath)

            // create a public capability for the collection
            signer.link<&{
                NonFungibleToken.Receiver,
                NonFungibleToken.CollectionPublic,
                GamePieceNFT.GamePieceNFTCollectionPublic,
                MetadataViews.ResolverCollection
            }>(
                GamePieceNFT.CollectionPublicPath,
                target: GamePieceNFT.CollectionStoragePath
            )

            // Link the Provider Capability in private storage
            signer.link<&{
                NonFungibleToken.Provider
            }>(
                GamePieceNFT.ProviderPrivatePath,
                target: GamePieceNFT.CollectionStoragePath
            )
        }

        /** --- Set user up with GamePlayer --- */
        //
        // Check if a GamePlayer already exists, pass this block if it does
        if signer.borrow<&RockPaperScissorsGame.GamePlayer>(from: RockPaperScissorsGame.GamePlayerStoragePath) == nil {
            // Create GamePlayer resource
            let gamePlayer <- RockPaperScissorsGame.createGamePlayer()
            // Save it
            signer.save(<-gamePlayer, to: RockPaperScissorsGame.GamePlayerStoragePath)
            // Link GamePlayerPublic Capability in public so player can be added to Matches
            signer.link<&{
                RockPaperScissorsGame.GamePlayerPublic
            }>(
                RockPaperScissorsGame.GamePlayerPublicPath,
                target: RockPaperScissorsGame.GamePlayerStoragePath
            )
            // Link GamePlayerID Capability in private
            signer.link<&
                {RockPaperScissorsGame.DelegatedGamePlayer, RockPaperScissorsGame.GamePlayerID}
            >(
                RockPaperScissorsGame.GamePlayerPrivatePath,
                target: RockPaperScissorsGame.GamePlayerStoragePath
            )
        }

        // Get the GamePlayerCapability which will be passed to the child account on creation
        let gamePlayerCap = signer
            .getCapability<&
                {RockPaperScissorsGame.DelegatedGamePlayer}
            >(
                RockPaperScissorsGame.GamePlayerPrivatePath
            )
        // Panic if the Capability is not valid
        if gamePlayerCap.borrow() == nil {
            panic("Problem with the GamePlayer Capability")
        }

        /** --- Set user up with ChildAccountManager --- */
        //
        // Check if ChildAccountManager already exists
        if signer.borrow<&ChildAccount.ChildAccountManager>(from: ChildAccount.ChildAccountManagerStoragePath) == nil {
            // Create and save the ChildAccountManager resource
            let manager <-ChildAccount.createChildAccountManager()
            signer.save(<-manager, to: ChildAccount.ChildAccountManagerStoragePath)
            // Link the public Capabilities
            signer.link<
                &{ChildAccount.ChildAccountManagerPublic, ChildAccount.ChildAccountManagerViewer}
            >(
                ChildAccount.ChildAccountManagerPublicPath,
                target: ChildAccount.ChildAccountManagerStoragePath
            )
        }

        // Get reference to ChildAccoutManager & create child account
        let managerRef = signer
            .borrow<
                &ChildAccount.ChildAccountManager
            >(
                from: ChildAccount.ChildAccountManagerStoragePath
            ) ?? panic("Couldn't get a reference to the signer's ChildAccountManager")

        // Check if a child account already exists with the given public key
        var pubKeyMatchesChild = false
        var childAddress: Address? = nil
        // Iterate over the parent's child account addresses
        for child in managerRef.getChildAccountAddresses() {
            // Get the childAccountInfo for the given address
            if let info = managerRef.getChildAccountInfo(address: child) {
                // Mark the child's address if its originating public key matches the one given
                if info.originatingPublicKey == pubKey {
                    pubKeyMatchesChild = true
                    childAddress = child
                    break
                }
            }
        }

        // Create the child account if the public key does not match any of the parent's
        // existing children accounts
        if !pubKeyMatchesChild {
            // Construct ChildAccountInfo struct from given arguments
            let info = ChildAccount.ChildAccountInfo(
                name: childAccountName,
                description: childAccountDescription,
                clientIconURL: MetadataViews.HTTPFile(url: clientIconURL),
                clienExternalURL: MetadataViews.ExternalURL(clientExternalURL),
                originatingPublicKey: pubKey
            )

            // Create the child account
            let newAccount = managerRef.createChildAccount(
                signer: signer,
                initialFundingAmount: fundingAmt,
                childAccountInfo: info
            )

            /* --- Set up child account with necessary resources --- */

            /** --- GamePieceNFT.Collection --- */
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
            
            // Assign the new account's address as the child address we're dealing with
            childAddress = newAccount.address
        }

        // Get a reference to the new account's CollectionPublic
        let collectionRef = getAccount(childAddress!)
            .getCapability<&
                {NonFungibleToken.CollectionPublic}
            >(
                GamePieceNFT.CollectionPublicPath
            ).borrow()
            ?? panic("Could not borrow reference to NFT.CollectionPublic for ".concat(childAddress!.toString()))

        // Mint an NFT if the child account's Collection is empty
        if collectionRef.getIDs().length == 0 {
            // Mint NFT to Collection
            GamePieceNFT.mintNFT(recipient: collectionRef)
        }

        // Ensure the ChildAccountTag has a DelegatedGamePlayer Capability
        // Get a reference to the child account's ChildAccountTag
        let tagRef: &ChildAccount.ChildAccountTag = managerRef
            .getChildAccountTagRef(address: childAddress!)
            ?? panic("Problem associating child account to parent account for child account ".concat(childAddress!.toString()))
        // If it doesn't have the DelegatedGamePlayer Capability, add it via the parent's ChildAccountManager
        if tagRef.getGrantedCapabilityAsRef(Type<Capability<&{RockPaperScissorsGame.DelegatedGamePlayer}>>()) == nil {
            managerRef.addCapability(to: childAddress!, gamePlayerCap)
        }
    }
}
