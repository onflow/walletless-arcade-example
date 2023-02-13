const GET_MATCHES_IN_PLAY = `
import RockPaperScissorsGame from 0xRockPaperScissorsGame

/// Script to get match IDs of matches for which player
/// has MatchLobbyActions Capabilities
///
pub fun main(address: Address): [UInt64] {
    
    let account = getAccount(address)

    let gamePlayerRef = account
        .getCapability(RockPaperScissorsGame.GamePlayerPublicPath)
        .borrow<&{RockPaperScissorsGame.GamePlayerPublic}>()
        ?? panic("Could not borrow capability from public collection at specified path")

    return gamePlayerRef.getMatchesInPlay()
}
`

export default GET_MATCHES_IN_PLAY
