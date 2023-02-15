import ChildAccount from "../../contracts/ChildAccount.cdc"
import MetadataViews from "../../contracts/utility/MetadataViews.cdc"

/// This transaction creates an account using the signer's public key at index 0,
/// using the ChildAccountManager with the signer as the account's payer
/// Additionally, the new account is funded with the specified amount of Flow
/// from the signing account's FlowToken Vault.AccountKey
/// NOTE: Public key assumes SignatureAlgorithm.ECDSA_P256
///
transaction(
        signerPubKeyIndex: Int,
        fundingAmt: UFix64,
        childAccountName: String,
        childAccountDescription: String,
        clientIconURL: String,
        clientExternalURL: String
    ) {

    prepare(signer: AuthAccount) {
        /** --- Set user up with ChildAccountManager --- */
        //
        // Check if ChildAccountManager already exists
        if signer.borrow<&ChildAccount.ChildAccountManager>(from: ChildAccount.ChildAccountManagerStoragePath) == nil {
            // Create and save the ChildAccountManager resource
            signer.save(<-ChildAccount.createChildAccountManager(), to: ChildAccount.ChildAccountManagerStoragePath)
        }
        if !signer.getCapability<&{ChildAccount.ChildAccountManagerViewer}>(ChildAccount.ChildAccountManagerPublicPath).check() {
            signer.link<
                &{ChildAccount.ChildAccountManagerViewer}
            >(
                ChildAccount.ChildAccountManagerPublicPath,
                target: ChildAccount.ChildAccountManagerStoragePath
            )
        }

        /* --- Creaate account --- */
        //
        // Get a reference to the signer's ChildAccountManager
        let managerRef = signer.borrow<
                &ChildAccount.ChildAccountManager
            >(
                from: ChildAccount.ChildAccountManagerStoragePath
            ) ?? panic(
                "No ChildAccountManager in signer's account at "
                .concat(ChildAccount.ChildAccountManagerStoragePath.toString())
            )
        // Get the signer's key at the specified index
        let key: AccountKey = signer.keys.get(keyIndex: signerPubKeyIndex) ?? panic("No key with given index")
        // Convert to string
        let pubKeyAsString = String.encodeHex(key.publicKey.publicKey)
        // Construct the ChildAccountInfo metadata struct
        let info = ChildAccount.ChildAccountInfo(
                name: childAccountName,
                description: childAccountDescription,
                clientIconURL: MetadataViews.HTTPFile(url: clientIconURL),
                clienExternalURL: MetadataViews.ExternalURL(clientExternalURL),
                originatingPublicKey: pubKeyAsString
            )
        // Create the account
        let newAccount = managerRef.createChildAccount(
            signer: signer,
            initialFundingAmount: fundingAmt,
            childAccountInfo: info,
            authAccountCapPath: ChildAccount.AuthAccountCapabilityPath
        )
    }
}
 