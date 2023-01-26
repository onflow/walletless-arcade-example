import FungibleToken from "../../contracts/utility/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import MetadataViews from "../../contracts/utility/MetadataViews.cdc"
import GamePieceNFT from "../../contracts/GamePieceNFT.cdc"
import RockPaperScissorsGame from "../../contracts/RockPaperScissorsGame.cdc"

/// This transaction sets up the following in a signer's account
/// - GamePieceNFT.Collection
/// - GamePieceNFT.NFT
/// - RockPaperScissorsGame.GamePlayer
///
/// Should be run before an account interacts with RockPaperScissorsGame
///
transaction(minterAddress: Address) {

    prepare(signer: AuthAccount) {
        
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
        // Grab Collection related references & Capabilities
        let collectionRef = signer.borrow<&GamePieceNFT.Collection>(from: GamePieceNFT.CollectionStoragePath)!
        
        /** --- Make sure signer has a GamePieceNFT.NFT to play with --- */
        //
        // Mint GamePieceNFT.NFT if one doesn't exist
        if collectionRef.getIDs().length == 0 {
            // Get a reference to the MinterPublic Capability
            let minterRef = getAccount(minterAddress)
                .getCapability<
                    &{GamePieceNFT.MinterPublic}
                >(
                    GamePieceNFT.MinterPublicPath
                ).borrow()
                ?? panic("Could not get a reference to the MinterPublic Capability at the specified address ".concat(minterAddress.toString()))
            minterRef.mintNFT(recipient: collectionRef)
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
                RockPaperScissorsGame.DelegatedGamePlayer
                RockPaperScissorsGame.GamePlayerID
            }>(
                RockPaperScissorsGame.GamePlayerPrivatePath,
                target: RockPaperScissorsGame.GamePlayerStoragePath
            )
        }
    }
}
