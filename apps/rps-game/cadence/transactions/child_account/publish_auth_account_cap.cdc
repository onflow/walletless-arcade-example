// import ChildAccount from "../../contracts/ChildAccount.cdc"
import ChildAccount from "../../contracts/ChildAuthAccount.cdc"

/// Signing account publishes a Capability to its AuthAccount for
/// the specified parentAddress to claim
///
transaction(parentAddress: Address) {

    let authAccountCap: Capability<&AuthAccount>

    prepare(signer: AuthAccount) {
        // Get the AuthAccount Capability, linking if necessary
        if !signer.getCapability<&AuthAccount>(ChildAccount.AuthAccountCapabilityPath).check() {
            self.authAccountCap = signer.linkAccount(ChildAccount.AuthAccountCapabilityPath)!
        } else {
            self.authAccountCap = signer.getCapability<&AuthAccount>(ChildAccount.AuthAccountCapabilityPath)
        }
        // Publish for the specified Address
        signer.inbox.publish(self.authAccountCap!, name: "AuthAccountCapability", recipient: parent)
    }
}