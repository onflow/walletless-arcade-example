import ChildAccount from "../../contracts/ChildAccount.cdc"

/// Creates and saves a ChildAccountManager resource in the signer's account
///
transaction {

    prepare(signer: AuthAccount) {
        // Return early if already configured
        if let ref = signer
            .borrow<&
                ChildAccount.ChildAccountManager
            >(from: ChildAccount.ChildAccountManagerStoragePath) {
            return
        }

        // Create and save the ChildAccountManager resource
        let manager <- ChildAccount.createChildAccountManager()
        signer.save(<-manager, to: ChildAccount.ChildAccountManagerStoragePath)
        // Link the public Capabilities
        signer.link<
                &{ChildAccount.ChildAccountManagerPublic, ChildAccount.ChildAccountManagerViewer}
            >(
                ChildAccount.ChildAccountManagerPublicPath,
                target: ChildAccount.ChildAccountManagerStoragePath
            )
    }

}
