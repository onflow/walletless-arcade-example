import NonFungibleToken from "../../../contracts/utility/NonFungibleToken.cdc"
import GamePieceNFT from "../../../contracts/GamePieceNFT.cdc"
import ChildAccount from "../../../contracts/ChildAccount.cdc"
import RockPaperScissorsGame from "../../../contracts/RockPaperScissorsGame.cdc"

/// Transaction that sets up GamePlayer resource in signing account
/// and exposes GamePlayerPublic capability so matches can be added
/// for the player to participate in
///
transaction(matchID: UInt64, escrowNFTID: UInt64) {

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

        // Get the account's Receiver Capability
        let receiverCap = account
            .getCapability<&
                AnyResource{NonFungibleToken.Receiver}
            >(GamePieceNFT.CollectionPublicPath)
        
        // Get a reference to the account's Provider
        let providerRef = account
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
 