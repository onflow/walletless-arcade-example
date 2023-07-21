import "RockPaperScissorsGame"

/// Validates correct configuration of GamePlayer resource & Capabilities
///
pub fun main(address: Address): Bool {
    
    let public = getAccount(address).getCapability<&{RockPaperScissorsGame.GamePlayerPublic}>(
            RockPaperScissorsGame.GamePlayerPublicPath
        )
    let private = getAuthAccount(address).getCapability<&{RockPaperScissorsGame.DelegatedGamePlayer, RockPaperScissorsGame.GamePlayerID}>(
            RockPaperScissorsGame.GamePlayerPrivatePath
        )

    return public.check() && private.check()
}