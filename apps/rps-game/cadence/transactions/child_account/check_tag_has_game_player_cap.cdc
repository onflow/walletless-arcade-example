import ChildAccount from "../../contracts/ChildAccount.cdc"
import RockPaperScissorsGame from "../../contracts/RockPaperScissorsGame.cdc"

/// This transaction panics if any aspect of a GamePlayer Capability
/// is not configured at the signer's ChildAccountTag.grantedCapabilies
/// or if the signer does not have a ChildAccountTag
///
transaction {

    let tagRef: &ChildAccount.ChildAccountTag
    let childAddress: Address

    prepare(childAccount: AuthAccount) {
        self.childAddress = childAccount.address
        // Get a reference to the signer's ChildAccountTag resource
        self.tagRef = childAccount.borrow<&
                ChildAccount.ChildAccountTag
            >(
                from: ChildAccount.ChildAccountTagStoragePath
            ) ?? panic("ChildAccountTag not accessible at path ".concat(ChildAccount.ChildAccountTagStoragePath.toString()))
        log(self.tagRef.getType().identifier)
    }

    execute {
        let capRef = self.tagRef
            .getGrantedCapabilityAsRef(
                Type<Capability<&{RockPaperScissorsGame.DelegatedGamePlayer}>>()
            ) ?? panic("Child account does not have GamePlayer Capability in its ChildAccountTag!")
        let gamePlayerRef = capRef
            .borrow<&{RockPaperScissorsGame.DelegatedGamePlayer}>()
            ?? panic("ChildAccountTag has invalid GamePlayerCapability")
    }
}
 