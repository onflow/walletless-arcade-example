import NonFungibleToken from "../../../contracts/utility/NonFungibleToken.cdc"
import RockPaperScissorsGame from "../../../contracts/RockPaperScissorsGame.cdc"
import GamePieceNFT from "../../../contracts/GamePieceNFT.cdc"

/// ReturnsNFTs from escrow to their owners' Receiver which
/// is stored in the Match resource itself
transaction(matchID: UInt64) {

    let matchPlayerActionsRef: &{RockPaperScissorsGame.MatchPlayerActions}
    let gamePlayerIDRef: &{RockPaperScissorsGame.GamePlayerID}
    let receiverCap: Capability<&{NonFungibleToken.Receiver}>
    
    prepare(acct: AuthAccount) {
        // Get the MatchPlayer reference from the GamePlayer resource
        let gamePlayerRef = acct
            .borrow<&RockPaperScissorsGame.GamePlayer>(from: RockPaperScissorsGame.GamePlayerStoragePath)
            ?? panic("Could not borrow GamePlayer reference!")
        // Assign the transaction's GamePlayerID reference
        self.gamePlayerIDRef = gamePlayerRef as &{RockPaperScissorsGame.GamePlayerID}
        
        // Get the MatchPlayerActions Capability from the GamePlayer
        let matchPlayerActionsCap: Capability<&{RockPaperScissorsGame.MatchPlayerActions}> = gamePlayerRef
            .getMatchPlayerCaps()[matchID]
            ?? panic("Could not retrieve MatchPlayer capability for given matchID!")
        // Assign the transaction's MatchPlayerActions reference
        self.matchPlayerActionsRef = matchPlayerActionsCap
            .borrow()
            ?? panic("Could not borrow Reference to MatchPlayerActions Capability!")

        // Get the signer's Receiver Capability
        self.receiverCap = acct.getCapability<
            &{NonFungibleToken.Receiver}
            >(
                GamePieceNFT.CollectionPublicPath
            )
    }

    execute {
        // Call for NFT to be returned to signing players' Receiver
        self.matchPlayerActionsRef.retrieveUnclaimedNFT(
            gamePlayerIDRef: self.gamePlayerIDRef,
            receiver: self.receiverCap
        )
    }
}
