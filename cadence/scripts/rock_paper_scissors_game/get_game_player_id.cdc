import "RockPaperScissorsGame"

/// Returns the GamePlayer.id of the GamePlayer resource
/// configured at the provided address if it exists
///
pub fun main(playerAddress: Address): UInt64? {

    let playerAccount = getAccount(playerAddress)

    // Try to get a reference to the GamePlayerPublic Capability
    if let gamePlayerPublicRef = playerAccount.getCapability<&{
            RockPaperScissorsGame.GamePlayerPublic
        }>(
            RockPaperScissorsGame.GamePlayerPublicPath
        ).borrow() {
        return gamePlayerPublicRef.id
    }

    // No reference found, return nil
    return nil
}
