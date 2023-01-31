import NonFungibleToken from "../../../contracts/utility/NonFungibleToken.cdc"
import MonsterMaker from "../../../contracts/MonsterMaker.cdc"
import RockPaperScissorsGame from "../../../contracts/RockPaperScissorsGame.cdc"

/// Transaction escrows the specified GamePieceNFT to the specified
/// Match.id for which the signer has a MatchLobbyActions in their GamePlayer
///
transaction(matchID: UInt64, escrowNFTID: UInt64) {

    prepare(acct: AuthAccount) {
        // Get the GamePlayer reference from the signing account's storage
        let gamePlayerRef = acct
            .borrow<&RockPaperScissorsGame.GamePlayer>(
                from: RockPaperScissorsGame.GamePlayerStoragePath
            ) ?? panic("Could not borrow GamePlayer reference!")

        // Get the account's Receiver Capability
        let receiverCap = acct.getCapability<
                &{NonFungibleToken.Receiver}
            >(
                MonsterMaker.CollectionPublicPath
            )
        
        // Get a reference to the account's Provider
        let providerRef = acct.borrow<
                &{NonFungibleToken.Provider}
            >(
                from: MonsterMaker.CollectionStoragePath
            ) ?? panic("Could not borrow reference to account's Provider")
        // Withdraw the desired NFT
        let nft <-providerRef.withdraw(withdrawID: escrowNFTID) as! @MonsterMaker.NFT
        
        // Escrow NFT
        gamePlayerRef
            .depositNFTToMatchEscrow(
                nft: <-nft,
                matchID: matchID,
                receiverCap: receiverCap
            )
    }
}
 