import RockPaperScissorsGame from "../../contracts/RockPaperScissorsGame.cdc"

/// Returns true if the given address has a GamePlayerPublic Capability
/// configured at the expected path. A player would run this script
/// to tell if another Address is able to engage in a RockPaperScissors
/// Match.
///
pub fun main(playerAddress: Address): Bool {
    return getAccount(playerAddress).getCapability<&{
            RockPaperScissorsGame.GamePlayerPublic
        }>(
            RockPaperScissorsGame.GamePlayerPublicPath
        ).check()
}
