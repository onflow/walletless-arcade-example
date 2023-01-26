import FungibleToken from "../../contracts/utility/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import MetadataViews from "../../contracts/utility/MetadataViews.cdc"
import GamePieceNFT from "../../contracts/GamePieceNFT.cdc"
import RockPaperScissorsGame from "../../contracts/RockPaperScissorsGame.cdc"
// import ChildAccount from "../../contracts/ChildAccount.cdc"
import ChildAccount from "../../contracts/ChildAuthAccount.cdc"

// TODO: Having issues with getting DelegatedGamePlayer Capability from signer
//
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
/// any assets in child accounts should be considered at risk if any party other than the signer has 
/// access to the given public key's paired private key. In the context of this repo, child accounts
/// are used by local game clients to facilitate a gameplay UX that does not require user transactions
/// at every step while still giving true ownership over game assets to the player. This setup is otherwise known as
/// a Hybrid Account construction - combining the benefits of app & non-custodial accounts.
/// While this approach does compromise on security, convenience is far improved. Given this security risk, only
/// trusted game clients should be used & users should consider moving very valuable assets to their parent account.
///
transaction(
        creatorAddress: Address,
        pubKey: String
    ) {

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
        if !signer.getCapability<&{
                NonFungibleToken.Receiver,
                NonFungibleToken.CollectionPublic,
                GamePieceNFT.GamePieceNFTCollectionPublic,
                MetadataViews.ResolverCollection
            }>(
                GamePieceNFT.CollectionPublicPath
            ).check() {
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
        }
        if !signer.getCapability<&{NonFungibleToken.Provider}>(GamePieceNFT.ProviderPrivatePath).check() {
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
        }
        if !signer.getCapability<&{RockPaperScissorsGame.GamePlayerPublic}>(RockPaperScissorsGame.GamePlayerPublicPath).check() {
            // Link GamePlayerPublic Capability so player can be added to Matches
            signer.link<&{
                RockPaperScissorsGame.GamePlayerPublic
            }>(
                RockPaperScissorsGame.GamePlayerPublicPath,
                target: RockPaperScissorsGame.GamePlayerStoragePath
            )
        }
        if !signer.getCapability<&{RockPaperScissorsGame.GamePlayerID, RockPaperScissorsGame.DelegatedGamePlayer}>(RockPaperScissorsGame.GamePlayerPrivatePath).check() {
            // Link GamePlayerID Capability
            signer.link<&{
                RockPaperScissorsGame.DelegatedGamePlayer,
                RockPaperScissorsGame.GamePlayerID
            }>(
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
        }
        if !signer.getCapability<&{ChildAccount.ChildAccountManagerViewer}>(ChildAccount.ChildAccountManagerPublicPath).check() {
            signer.link<
                &{ChildAccount.ChildAccountManagerViewer}
            >(
                ChildAccount.ChildAccountManagerPublicPath,
                target: ChildAccount.ChildAccountManagerStoragePath
            )
        }

        /* --- Link parent & child accounts --- */
        //
        // Get a reference to the ChildAccountCreator from the specified Address
        let creatorRef = getAccount(creatorAddress).getCapability<
                &{ChildAccount.ChildAccountCreatorPublic}
            >(
                ChildAccount.ChildAccountCreatorPublicPath
            ).borrow()
            ?? panic("Could not refer to ChildAccountCreatorPublic at address ".concat(creatorAddress.toString()))
        // Get the address of the child account created with the public key
        let childAddress = creatorRef.getAddressFromPublicKey(publicKey: pubKey)
            ?? panic("Could not find address created with public key ".concat(pubKey).concat(" by ChildAccountCreator at " ).concat(creatorAddress.toString()))
        // Get the Capability to the child's AuthAccount & get its reference
        let childAuthAccountCap = signer.inbox.claim<&AuthAccount>("AuthAccountCapability", provider: childAddress)!
        let childAuthAccountRef = childAuthAccountCap.borrow() ?? panic("Problem with child account's AuthAccount Capability!")
        // Get a reference to the ChildAccountTag that should be stored in the child account as it should have been added by ChildAccountCreator on creation
        let childAccountTagRef = childAuthAccountRef
            .borrow<&
                ChildAccount.ChildAccountTag
            >(
                from: ChildAccount.ChildAccountTagStoragePath
            ) ?? panic("Problem with child account's ChildAccountTag Capability!")
        let info = childAccountTagRef.info

        // Get reference to signer's ChildAccoutManager
        let managerRef = signer
            .borrow<
                &ChildAccount.ChildAccountManager
            >(
                from: ChildAccount.ChildAccountManagerStoragePath
            ) ?? panic("Couldn't get a reference to the signer's ChildAccountManager")
        // Add the child account to the ChildAccountManager so its AuthAccountCapability can be maintained
        managerRef.addAsChildAccount(childAccountCap: childAuthAccountCap, childAccountInfo: info)
        // Grant the child account a DelegatedGamePlayer Capability so it can play RockPaperScissorsGame Matches on behalf of the parent
        managerRef.addCapability(to: childAuthAccountRef.address, gamePlayerCap)

        // TODO: Setup Collection in child account
        // TODO: Mint NFT to child account
    }
}
 