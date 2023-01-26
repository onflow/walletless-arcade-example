import NonFungibleToken from "../../../contracts/utility/NonFungibleToken.cdc"
import GamePieceNFT from "../../../contracts/GamePieceNFT.cdc"
import ChildAccount from "../../../contracts/ChildAccount.cdc"
import RockPaperScissorsGame from "../../../contracts/RockPaperScissorsGame.cdc"

/// Transaction that creates a new Match in single player mode and 
/// escrows the specified NFT from the signing account's Collection
///
transaction(submittingNFTID: UInt64, matchTimeLimitInMinutes: UInt) {
    
    prepare(account: AuthAccount) {
        // Get reference to signer's ChildAccountTag
        let childAccountTagRef = account.borrow<&
                ChildAccount.ChildAccountTag
            >(
                from: ChildAccount.ChildAccountTagStoragePath
            ) ?? panic("Could not borrow reference to signer's ChildAccountTag")

        // Get a reference to the GamePlayer resource in the signing account's storage
        let capRef: &Capability = childAccountTagRef.getGrantedCapabilityAsRef(
                Type<Capability<&{RockPaperScissorsGame.DelegatedGamePlayer}>>()
            ) ?? panic("Could not borrow DelegatedGamePlayer Capability reference from ChildAccountTag!")

        let gamePlayerRef = capRef
            .borrow<&
                {RockPaperScissorsGame.DelegatedGamePlayer}
            >() ?? panic("Reference to DelegatedGamePlayer not accessible through ChildAccountTag's granted Capability!")
        
        let receiverCap = account.getCapability<&
                AnyResource{NonFungibleToken.Receiver}
            >(GamePieceNFT.CollectionPublicPath)
        
        // Get a reference to the account's Provider
        let providerRef = account.borrow<&{
                NonFungibleToken.Provider
            }>(
                from: GamePieceNFT.CollectionStoragePath
            ) ?? panic("Could not borrow reference to account's Provider")
        // Withdraw the desired NFT
        let submittingNFT <-providerRef.withdraw(withdrawID: submittingNFTID) as! @GamePieceNFT.NFT

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
 