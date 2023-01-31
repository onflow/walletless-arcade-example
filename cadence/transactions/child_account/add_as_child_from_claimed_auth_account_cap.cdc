import ChildAccount from "../../contracts/ChildAccount.cdc"
import MetadataViews from "../../contracts/utility/MetadataViews.cdc"

/// Signing account claims a Capability to specified Address's AuthAccount
/// and adds it as a child account in its ChildAccountManager, allowing it 
/// to maintain the claimed Capability
///
transaction(
        pubKey: String,
        childAddress: Address,
        childAccountName: String,
        childAccountDescription: String,
        clientIconURL: String,
        clientExternalURL: String
    ) {

    let managerRef: &ChildAccount.ChildAccountManager
    let info: ChildAccount.ChildAccountInfo
    let childAccountCap: Capability<&AuthAccount>

    prepare(signer: AuthAccount) {
        // Get ChildAccountManager Capability, linking if necessary
        if signer.borrow<
                &ChildAccount.ChildAccountManager
            >(
                from: ChildAccount.ChildAccountManagerStoragePath
            ) == nil {
            // Save a ChildAccountManager to the signer's account
            signer.save(<-ChildAccount.createChildAccountManager(), to: ChildAccount.ChildAccountManagerStoragePath)
        }
        // Ensure ChildAccountManagerViewer is linked properly
        if !signer.getCapability<
                &{ChildAccount.ChildAccountManagerViewer}
            >(
                ChildAccount.ChildAccountManagerPublicPath
            ).check() {
            // Link
            signer.link<
                &{ChildAccount.ChildAccountManagerViewer}
            >(
                ChildAccount.ChildAccountManagerPublicPath,
                target: ChildAccount.ChildAccountManagerStoragePath
            )
        }
        // Get ChildAccountManager reference from signer
        self.managerRef = signer.borrow<
                &ChildAccount.ChildAccountManager
            >(
                from: ChildAccount.ChildAccountManagerStoragePath
            )!
        // Claim the previously published AuthAccount Capability from the given Address
        self.childAccountCap = signer.inbox
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
        // TODO: Alternately could get pubKey from account key index 0
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
        self.managerRef.addAsChildAccount(childAccountCap: self.childAccountCap, childAccountInfo: self.info)
    }
}