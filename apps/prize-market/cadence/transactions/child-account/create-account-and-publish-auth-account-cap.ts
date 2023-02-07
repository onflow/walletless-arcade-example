const CREATE_ACCOUNT_AND_PUBLISH_AUTH_ACCOUNT_CAP = `
import ChildAccount from 0xChildAccount
import MetadataViews from 0xMetadataViews

/// This transaction creates an account from the given public key, using the
/// ChildAccountCreator with the signer as the account's payer, additionally
/// funding the new account with the specified amount of Flow from the signer's
/// account
///
transaction(
        publishFor: Address,
        pubKey: String,
        fundingAmt: UFix64,
        childAccountName: String,
        childAccountDescription: String,
        clientIconURL: String,
        clientExternalURL: String
    ) {

    prepare(signer: AuthAccount) {
        // Get a reference to the signer's ChildAccountCreator
        let creatorRef = signer.borrow<
                &ChildAccount.ChildAccountCreator
            >(
                from: ChildAccount.ChildAccountCreatorStoragePath
            ) ?? panic(
                "No ChildAccountCreator in signer's account at "
                .concat(ChildAccount.ChildAccountCreatorStoragePath.toString())
            )
        // Construct the ChildAccountInfo metadata struct
        let info = ChildAccount.ChildAccountInfo(
                name: childAccountName,
                description: childAccountDescription,
                clientIconURL: MetadataViews.HTTPFile(url: clientIconURL),
                clienExternalURL: MetadataViews.ExternalURL(clientExternalURL),
                originatingPublicKey: pubKey
            )
        // Create the account
        let newAccount = creatorRef.createChildAccount(
            signer: signer,
            initialFundingAmount: fundingAmt,
            childAccountInfo: info
        )
        // Link the account's AuthAccount Capability
        let authAccountCap = newAccount.linkAccount(ChildAccount.AuthAccountCapabilityPath)
        // Publish for the parent account to claim the AuthAccount Capability
        newAccount.inbox.publish(authAccountCap!, name: "AuthAccountCapability", recipient: publishFor)
    }
}
`

export default CREATE_ACCOUNT_AND_PUBLISH_AUTH_ACCOUNT_CAP
