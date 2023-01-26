import RockPaperScissorsGame from "../../../contracts/RockPaperScissorsGame.cdc"
import ChildAccount from "../../../contracts/ChildAccount.cdc"

/// Transaction to submit player's move
/// int moves: 0 rock, 1 paper, 2 scissors
///
transaction(matchID: UInt64, move: UInt8) {
    
    let gamePlayerRef: &{RockPaperScissorsGame.DelegatedGamePlayer}
    let moveAsEnum: RockPaperScissorsGame.Moves

    prepare(account: AuthAccount) {
        // Get reference to signer's ChildAccountTag
        let childAccountTag = account.borrow<&
                ChildAccount.ChildAccountTag
            >(
                from: ChildAccount.ChildAccountTagStoragePath
            ) ?? panic("Could not borrow reference to signer's ChildAccountTag")

        // Get a reference to the DelegatedGamePlayer Capability contained in the ChildAccountTag
        // which has been granted by the parent account's ChildAccountManager
        let capRef: &Capability = childAccountTag.getGrantedCapabilityAsRef(
                Type<Capability<&{RockPaperScissorsGame.DelegatedGamePlayer}>>()
            ) ?? panic("Could not borrow DelegatedGamePlayer Capability reference from ChildAccountTag!")

        // Borrow a reference to the DelegatedGamePlayer through the referenced Capability
        self.gamePlayerRef = capRef
            .borrow<&
                {RockPaperScissorsGame.DelegatedGamePlayer}
            >() ?? panic("Reference to DelegatedGamePlayer not accessible through ChildAccountTag's granted Capability!")

        // Construct a legible move from the raw input value
        self.moveAsEnum = RockPaperScissorsGame
            .Moves(
                rawValue: move
            ) ?? panic("Given move does not map to a legal RockPaperScissorsGame.Moves value!")
    }

    execute {
        // Submit moves for the game
        self.gamePlayerRef.submitMoveToMatch(matchID: matchID, move: self.moveAsEnum)
        RockPaperScissorsGame.submitAutomatedPlayerMove(matchID: matchID)
    }
}
 