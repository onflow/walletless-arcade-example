import "AccountCreator"

/// Configures and AccountCreator resource in the signer's account
/// **NOTE:** AccountCreator is used here to keep the demo app client-side & simple and should be replaced by an
/// an an account creation + database or custodial service in a production environment.
///
transaction {
    prepare(signer: AuthAccount) {

        // Ensure resource is saved where expected
        if signer.type(at: AccountCreator.CreatorStoragePath) == nil {
            signer.save(<-AccountCreator.createNewCreator(), to: AccountCreator.CreatorStoragePath)
        }
        // Ensure public Capability is linked
        if !signer.getCapability<&AccountCreator.Creator{AccountCreator.CreatorPublic}>(
            AccountCreator.CreatorPublicPath
        ).check() {
            // Link the public Capability
            signer.unlink(AccountCreator.CreatorPublicPath)
            signer.link<&AccountCreator.Creator{AccountCreator.CreatorPublic}>(
                AccountCreator.CreatorPublicPath,
                target: AccountCreator.CreatorStoragePath
            )
        }
    }
}