import RockPaperScissorsGame from "../../../contracts/RockPaperScissorsGame.cdc"
import ChildAccount from "../../../contracts/ChildAccount.cdc"

/// Transaction to resolve a Match
///
transaction(matchID: UInt64) {
    
    let gamePlayerRef: &{RockPaperScissorsGame.DelegatedGamePlayer}

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
    }

    execute {
        // Submit moves for the game
        self.gamePlayerRef.resolveMatchByID(matchID)
    }
}
 