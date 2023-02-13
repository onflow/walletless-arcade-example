const SETUP_CHILD_ACCOUNT_CREATOR = `
import ChildAccount from 0xChildAccount

/// Sets up a ChildAccountCreator in signer's account to enable creation of
/// accounts & querying created addresses from the originating public key
///
transaction {
    prepare(signer: AuthAccount) {
        // Return early if already configured
        if let ref = signer.borrow<&ChildAccount.ChildAccountCreator>
                                (from: ChildAccount.ChildAccountCreatorStoragePath) {
            return
        }
        signer.save(
            <-ChildAccount.createChildAccountCreator(),
            to: ChildAccount.ChildAccountCreatorStoragePath
        )
        // Link the public Capability
        signer.link<
                &{ChildAccount.ChildAccountCreatorPublic}
            >(
                ChildAccount.ChildAccountCreatorPublicPath,
                target: ChildAccount.ChildAccountCreatorStoragePath
            )
    }
}
`

export default SETUP_CHILD_ACCOUNT_CREATOR
