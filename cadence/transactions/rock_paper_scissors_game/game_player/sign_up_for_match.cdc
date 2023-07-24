import "NonFungibleToken"
import "RockPaperScissorsGame"

/// The signer signs up for the specified Match.id, setting up a GamePlayer resource
/// if need be in the process. This gives the signer the ability to engage with an
/// RPSGame Match
///
transaction(matchID: UInt64) {

    let gamePlayerRef: &RockPaperScissorsGame.GamePlayer

    prepare(signer: AuthAccount) {
        // Check if a GamePlayer already exists, pass this block if it does
        if signer.borrow<&RockPaperScissorsGame.GamePlayer>(from: RockPaperScissorsGame.GamePlayerStoragePath) == nil {
            // Create GamePlayer resource
            let gamePlayer <- RockPaperScissorsGame.createGamePlayer()
            // Save it
            signer.save(<-gamePlayer, to: RockPaperScissorsGame.GamePlayerStoragePath)
        }
        // Make sure the public capability is properly linked
        if !signer.getCapability<&{RockPaperScissorsGame.GamePlayerPublic}>(RockPaperScissorsGame.GamePlayerPublicPath).check() {
            signer.unlink(RockPaperScissorsGame.GamePlayerPublicPath)
            // Link GamePlayerPublic Capability so player can be added to Matches
            signer.link<&{
                RockPaperScissorsGame.GamePlayerPublic
            }>(
                RockPaperScissorsGame.GamePlayerPublicPath,
                target: RockPaperScissorsGame.GamePlayerStoragePath
            )
        }
        // Make sure the private capability is properly linked
        if !signer.getCapability<&{RockPaperScissorsGame.GamePlayerID}>(RockPaperScissorsGame.GamePlayerPrivatePath).check() {
            signer.unlink(RockPaperScissorsGame.GamePlayerPublicPath)
            // Link GamePlayerID Capability
            signer.link<&{
                RockPaperScissorsGame.GamePlayerID
            }>(
                RockPaperScissorsGame.GamePlayerPrivatePath,
                target: RockPaperScissorsGame.GamePlayerStoragePath
            )
        }
        // Get the GamePlayer reference from the signing account's storage
        self.gamePlayerRef = signer
            .borrow<&RockPaperScissorsGame.GamePlayer>(
                from: RockPaperScissorsGame.GamePlayerStoragePath
            )!
    }

    execute {
        // Sign up for Match - no guarantee match is playable, but gives access to MatchLobbyActions
        self.gamePlayerRef.signUpForMatch(matchID: matchID)
    }
}
 