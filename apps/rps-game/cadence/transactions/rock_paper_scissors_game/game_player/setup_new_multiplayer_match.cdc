import NonFungibleToken from "../../../contracts/utility/NonFungibleToken.cdc"
import GamePieceNFT from "../../../contracts/GamePieceNFT.cdc"
import RockPaperScissorsGame from "../../../contracts/RockPaperScissorsGame.cdc"

/// Transaction that creates a new Match in multiplayer mode, escrows the 
/// specified NFT from the signer's Collection, and adds the MatchLobbyActions
/// Capability to the GamePlayerPublic of the specified playerTwoAddr
///
transaction(submittingNFTID: UInt64, playerTwoAddr: Address, matchTimeLimitInMinutes: UInt) {
    
    let gamePlayerRef: &RockPaperScissorsGame.GamePlayer
    let gamePlayerTwoPublicRef: &AnyResource{RockPaperScissorsGame.GamePlayerPublic}
    let newMatchID: UInt64
    
    prepare(acct: AuthAccount) {
        // Get a reference to the GamePlayer resource in the signing account's storage
        self.gamePlayerRef = acct
            .borrow<&RockPaperScissorsGame.GamePlayer>(
                from: RockPaperScissorsGame.GamePlayerStoragePath
            ) ?? panic("Could not borrow GamePlayer reference!")
        
        // Get the second player's account
        let playerTwoAccount = getAccount(playerTwoAddr)
        // Get the second player's GamePlayerPublic reference
        self.gamePlayerTwoPublicRef = playerTwoAccount
            .getCapability<&AnyResource{RockPaperScissorsGame.GamePlayerPublic}>(
                RockPaperScissorsGame.GamePlayerPublicPath
            ).borrow()
            ?? panic("GamePlayerPublic not accessible at address ".concat(playerTwoAddr.toString()))
        
        let receiverCap = acct.getCapability<&
                AnyResource{NonFungibleToken.Receiver}
            >(GamePieceNFT.CollectionPublicPath)
        
        // Get a reference to the account's Provider
        let providerRef = acct.borrow<&{
                NonFungibleToken.Provider
            }>(
                from: GamePieceNFT.CollectionStoragePath
            ) ?? panic("Could not borrow reference to account's Provider")
        // Withdraw the desired NFT
        let submittingNFT <-providerRef.withdraw(withdrawID: submittingNFTID) as! @GamePieceNFT.NFT

        // Create a match with the given timeLimit in minutes
        self.newMatchID = self.gamePlayerRef
            .createMatch(
                multiPlayer: true,
                matchTimeLimit: UFix64(matchTimeLimitInMinutes) * UFix64(60000),
                nft: <-submittingNFT,
                receiverCap: receiverCap
            )
    }

    execute {
        // Then add the MatchPlayerActions for the match to each player's GamePlayer resource 
        // via the GamePlayerPublic reference
        self.gamePlayerRef
            .addPlayerToMatch(
                matchID: self.newMatchID,
                gamePlayerRef: self.gamePlayerTwoPublicRef
            )
    }
}
 