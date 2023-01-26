// import ChildAccount from "../../contracts/ChildAccount.cdc"
import ChildAccount from "../../contracts/ChildAuthAccount.cdc"

/// Signing account claims a Capability to specified Address's AuthAccount
/// and adds it as a child account in its ChildAccountManager, allowing it 
/// to maintain the claimed Capability
///
transaction(
        childAddress: Address,
        childAccountName: String,
        childAccountDescription: String,
        clientIconURL: String,
        clientExternalURL: String
    ) {

    let managerRef: &ChildAccount.ChildAccountManager
    let info: ChildAccount.ChildAccountInfo

    prepare(signer: AuthAccount) {
        // Get ChildAccountManager Capability, linking if necessary
        if signer.borrow<
                &ChildAccount.ChildAccountManager
            >(
                from: ChildAccount.ChildAcccountManagerStoragePath
            ) == nil {
            // Save a ChildAccountManager to the signer's account
            signer.save(<-ChildAccount.createChildAccountManager(), to: ChildAccount.ChildAcccountManagerStoragePath)
        }
        // Ensure ChildAccountManagerViewer is linked properly
        if !signer.getCapability<
                &{ChildAccount.ChildAccountManagerViewer}
            >(
                ChildAccount.ChildAccountManagerPublicPath
            ).check() {
            // Link
            signer.link<
                &{ChildAccountManagerViewer}
            >(
                ChildAccount.ChildAccountManagerPublicPath,
                target: ChildAccount.ChildAccountManagerStoragePath
            )
        }
        // Get ChildAccountManager reference from signer
        self.managerRef = signer.borrow<
                &ChildAccount.ChildAccountManager
            >(
                from: ChildAccount.ChildAcccountManagerStoragePath
            )!
        // Claim the previously published AuthAccount Capability from the given Address
        let childAuthAccountCap = signer.inbox
            .claim<
                &AuthAccount
            >(
                "AuthAccountCapability",
                provider: childAddress
            ) ?? panic(
                "No AuthAccount Capability available from given provider"
                .concat(childAddress.toString())
                .concat(" with name ")
                .concat("AuthAccountCapability")
            )
        // Construct ChildAccountInfo struct from given arguments
        self.info = ChildAccount.ChildAccountInfo(
            name: childAccountName,
            description: childAccountDescription,
            clientIconURL: MetadataViews.HTTPFile(url: clientIconURL),
            clienExternalURL: MetadataViews.ExternalURL(clientExternalURL),
            originatingPublicKey: pubKey
        )
    }

    execute {
        // Add account as child to the ChildAccountManager
        self.managerRef.addAsChildAccount(childAccountCap: childAuthAccountCap, childAccountInfo: self.info)
    }
}