import ChildAccount from "../../contracts/ChildAccount.cdc"

/// Adds the labeled child account as a Child Account in the parent accounts'
/// ChildAccountManager resource. The parent is given key access to the child
/// account. Requires transaction be signed by both parties
///
transaction(
    childAccountName: String,
    childAccountDescription: String,
    clientIconURL: String,
    clientExternalURL: String
) {

    let authAccountCap: Capability<&AuthAccount>

    prepare(parent: AuthAccount, child: AuthAccount) {
        // Get ChildAccountManager Capability, linking if necessary
        if parent.borrow<&ChildAccount.ChildAccountManager>(from: ChildAccount.ChildAcccountManagerStoragePath) == nil {
            // Save
            parent.save(<-ChildAccount.createChildAccountManager(), to: ChildAccount.ChildAcccountManagerStoragePath)
        }
        // Ensure ChildAccountManagerViewer is linked properly
        if !parent.getCapability<&{ChildAccount.ChildAccountManagerViewer}>(ChildAccount.ChildAccountManagerPublicPath).check() {
            // Link
            parent.link<
                &{ChildAccountManagerViewer}
            >(
                ChildAccount.ChildAccountManagerPublicPath,
                target: ChildAccount.ChildAccountManagerStoragePath
            )
        }
        // Get a reference to the ChildAcccountManager resource
        if let managerRef = parent
            .getCapability<
                {&ChildAccount.ChildAccountManagerPublic}
            >(
                ChildAccount.ChildAccountManagerPublicPath
            ).borrow() {
        }

        // Get the AuthAccount Capability, linking if necessary
        if !child.getCapability<&AuthAccount>(ChildAccount.AuthAccountCapabilityPath).check() {
            // Unlink any Capability that may be there
            child.unlink(ChildAccount.AuthAccountCapabilityPath)
            // Link & assign the AuthAccount Capability
            self.authAccountCap = child.linkAccount(ChildAccount.AuthAccountCapabilityPath)!
        } else {
            // Assign the AuthAccount Capability
            self.authAccountCap = child.getCapability<&AuthAccount>(ChildAccount.AuthAccountCapabilityPath)
        }

        // Construct the child account's metadata from the given arguments
        let info = ChildAccount.ChildAccountInfo(
                name: childAccountName,
                description: childAccountDescription,
                clientIconURL: MetadataViews.HTTPFile(url: clientIconURL),
                clienExternalURL: MetadataViews.ExternalURL(clientExternalURL),
                originatingPublicKey: pubKey
            )

        // Add the child account
        managerRef.addAsChildAccount(newAccount: child, childAccountInfo: info)
    }
}
