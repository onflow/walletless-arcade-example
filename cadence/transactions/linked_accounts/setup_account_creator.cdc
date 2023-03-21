import AccountCreator from "../../contracts/utility/AccountCreator.cdc"

/// Sets up an AccountCreator in signer's account to enable creation of accounts & querying created addresses from th
/// originating public key
///
transaction {
    prepare(signer: AuthAccount) {
        // Ensure resource is saved where expected
        if signer.type(at: AccountCreator.CreatorStoragePath) == nil {
            signer.save(
                <-AccountCreator.createNewCreator(),
                to: AccountCreator.CreatorStoragePath
            )
        }
        // Ensure public Capability is linked
        if !signer.getCapability<&AccountCreator.Creator{AccountCreator.CreatorPublic}>(
            AccountCreator.CreatorPublicPath).check() {
            // Link the public Capability
            signer.unlink(AccountCreator.CreatorPublicPath)
            signer.link<&AccountCreator.Creator{AccountCreator.CreatorPublic}>(
                AccountCreator.CreatorPublicPath,
                target: AccountCreator.CreatorStoragePath
            )
        }
    }
}