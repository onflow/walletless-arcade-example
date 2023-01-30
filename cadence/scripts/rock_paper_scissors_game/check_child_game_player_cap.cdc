import ChildAccount from "../../contracts/ChildAccount.cdc"
import RockPaperScissorsGame from "../../contracts/RockPaperScissorsGame.cdc"

/// Returns true if ChildAccountTag at given Address has a
/// RockPaperScissorsGame.DelegatedGamePlayer Capability and
/// false if it does not. If no ChildAccountTagPublic reference 
/// is available at the address, nil is returned
///
pub fun main(childAddress: Address): Bool? {

    // Get a ref to the parentAddress's ChildAccountManagerViewer if possible
    if let tagRef = getAccount(childAddress).getCapability<&{
            ChildAccount.ChildAccountTagPublic
        }>(
            ChildAccount.ChildAccountTagPublicPath
        ).borrow() {

        return tagRef
            .getGrantedCapabilityTypes()
            .contains(
                Type<Capability<&{RockPaperScissorsGame.DelegatedGamePlayer}>>()
            )
    }

    return nil
}
