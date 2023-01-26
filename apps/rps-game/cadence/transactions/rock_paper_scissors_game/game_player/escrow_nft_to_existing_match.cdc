import NonFungibleToken from "../../../contracts/utility/NonFungibleToken.cdc"
import GamePieceNFT from "../../../contracts/GamePieceNFT.cdc"
import RockPaperScissorsGame from "../../../contracts/RockPaperScissorsGame.cdc"

/// Transaction that sets up GamePlayer resource in signing account
/// and exposes GamePlayerPublic capability so matches can be added
/// for the player to participate in
///
transaction(matchID: UInt64, escrowNFTID: UInt64) {

    prepare(acct: AuthAccount) {
        // Get the GamePlayer reference from the signing account's storage
        let gamePlayerRef = acct
            .borrow<&RockPaperScissorsGame.GamePlayer>(
                from: RockPaperScissorsGame.GamePlayerStoragePath
            ) ?? panic("Could not borrow GamePlayer reference!")

        // Get the account's Receiver Capability
        let receiverCap = acct
            .getCapability<&
                AnyResource{NonFungibleToken.Receiver}
            >(GamePieceNFT.CollectionPublicPath)
        
        // Get a reference to the account's Provider
        let providerRef = acct
            .borrow<&{
                NonFungibleToken.Provider
            }>(
                from: GamePieceNFT.CollectionStoragePath
            ) ?? panic("Could not borrow reference to account's Provider")
        // Withdraw the desired NFT
        let nft <-providerRef.withdraw(withdrawID: escrowNFTID) as! @GamePieceNFT.NFT
        
        // Escrow NFT
        gamePlayerRef
            .depositNFTToMatchEscrow(
                nft: <-nft,
                matchID: matchID,
                receiverCap: receiverCap
            )
    }
}
 