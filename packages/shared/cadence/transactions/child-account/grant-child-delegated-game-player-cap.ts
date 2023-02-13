const GRANT_CHILD_DELEGATED_GAME_PLAYER_CAP = `
import ChildAccount from 0xChildAccount
import MetadataViews from 0xMetadataViews
import RockPaperScissorsGame from 0xRockPaperScissorsGame

/// Gives a GamePlayer capability to a child account via the signer's 
/// ChildAccountManager. If a GamePlayer doesn't exist in the signer's
/// account, one is created & linked.
///
transaction(childAddress: Address) {

    prepare(signer: AuthAccount) {

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
        
        // Get the GamePlayer Capability
        let gamePlayerCap = signer.getCapability<&
                {RockPaperScissorsGame.DelegatedGamePlayer}
            >(
                RockPaperScissorsGame.GamePlayerPrivatePath
            )

        /** --- Add the Capability to the child's ChildAccountTag --- */
        //
        // Get a reference to the ChildAcccountManager resource
        let managerRef = signer
            .borrow<&
                ChildAccount.ChildAccountManager
            >(from: ChildAccount.ChildAccountManagerStoragePath)
            ?? panic("Signer does not have a ChildAccountManager configured")
        
        // Grant the GamePlayer Capability to the child account
        managerRef.addCapability(to: childAddress, gamePlayerCap)
    }
}
`

export default GRANT_CHILD_DELEGATED_GAME_PLAYER_CAP
