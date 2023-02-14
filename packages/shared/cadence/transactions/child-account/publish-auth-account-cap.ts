const PUBLISH_AUTH_ACCOUNT_CAP = `
import ChildAccount from 0xChildAccount

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
        signer.inbox.publish(self.authAccountCap!, name: "AuthAccountCapability", recipient: parentAddress)
    }
}
`

export default PUBLISH_AUTH_ACCOUNT_CAP
