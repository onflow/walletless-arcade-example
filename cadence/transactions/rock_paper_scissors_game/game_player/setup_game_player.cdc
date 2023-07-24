import "RockPaperScissorsGame"

/// Transaction that sets up GamePlayer resource in signing account
/// and exposes GamePlayerPublic capability so matches can be added
/// for the player to participate in as well as and GamePlayerID
/// in private so the user can provide Capabilities at their discretion.
///
transaction {

    prepare(signer: AuthAccount) {
        if signer.borrow<&{RockPaperScissorsGame.GamePlayerPublic}>(from: RockPaperScissorsGame.GamePlayerStoragePath) == nil {
            // Create & save GamePlayer resource
            signer.save(<-RockPaperScissorsGame.createGamePlayer(), to: RockPaperScissorsGame.GamePlayerStoragePath)
        }
        // Link GamePlayerPublic Capability so player can be added to Matches
        if !signer.getCapability<&{RockPaperScissorsGame.GamePlayerPublic}>(RockPaperScissorsGame.GamePlayerPublicPath).check() {
            signer.unlink(RockPaperScissorsGame.GamePlayerPublicPath)
            signer.link<&
                {RockPaperScissorsGame.GamePlayerPublic}
            >(
                RockPaperScissorsGame.GamePlayerPublicPath,
                target: RockPaperScissorsGame.GamePlayerStoragePath
            )
        }
        // Link GamePlayerID & DelegatedGamePlayer Capability
        if !signer.getCapability<&{RockPaperScissorsGame.DelegatedGamePlayer, RockPaperScissorsGame.GamePlayerID}>(
                RockPaperScissorsGame.GamePlayerPrivatePath
            ).check() {
            signer.unlink(RockPaperScissorsGame.GamePlayerPrivatePath)
            signer.link<&{
                RockPaperScissorsGame.DelegatedGamePlayer,
                RockPaperScissorsGame.GamePlayerID
            }>(
                RockPaperScissorsGame.GamePlayerPrivatePath,
                target: RockPaperScissorsGame.GamePlayerStoragePath
            )
        }
    }

}
