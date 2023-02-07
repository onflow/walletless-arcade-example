const SETUP_NEW_SINGLEPLAYER_MATCH = `
import NonFungibleToken from 0xNonFungibleToken
import MonsterMaker from 0xMonsterMaker
import RockPaperScissorsGame from 0xRockPaperScissorsGame

/// Transaction that creates a new Match in single player mode and 
/// escrows the specified NFT from the signing account's Collection
///
transaction(submittingNFTID: UInt64, matchTimeLimitInMinutes: UInt) {
    
    prepare(acct: AuthAccount) {
        // Get a reference to the GamePlayer resource in the signing account's storage
        let gamePlayerRef = acct
            .borrow<&RockPaperScissorsGame.GamePlayer>(
                from: RockPaperScissorsGame.GamePlayerStoragePath
            ) ?? panic("Could not borrow GamePlayer reference!")
        
        let receiverCap = acct.getCapability<
                &{NonFungibleToken.Receiver}
            >(
                MonsterMaker.CollectionPublicPath
            )
        
        // Get a reference to the account's Provider
        let providerRef = acct.borrow<&{
                NonFungibleToken.Provider
            }>(
                from: MonsterMaker.CollectionStoragePath
            ) ?? panic("Could not borrow reference to account's Provider")
        // Withdraw the desired NFT
        let submittingNFT <-providerRef.withdraw(withdrawID: submittingNFTID) as! @MonsterMaker.NFT

        // Create a match with the given timeLimit in minutes
        let newMatchID = gamePlayerRef
            .createMatch(
                multiPlayer: false,
                matchTimeLimit: UFix64(matchTimeLimitInMinutes) * UFix64(60000),
                nft: <-submittingNFT,
                receiverCap: receiverCap
            )
    }
}
`

export default SETUP_NEW_SINGLEPLAYER_MATCH
