import RockPaperScissorsGame from "../../contracts/RockPaperScissorsGame.cdc"

/// Reverts is the GamePlayerID Capability is not configured on the signer's
/// account at the expected PrivatePath
///
transaction {

    prepare(signer: AuthAccount) {
        let gamePlayerIDRef: &{RockPaperScissorsGame.GamePlayerID} = signer
            .getCapability<
                &{RockPaperScissorsGame.GamePlayerID}
            >(
                RockPaperScissorsGame.GamePlayerPrivatePath
            ).borrow()
            ?? panic("Could not borrow reference to signer's GamePlayerID capability")
    }
}