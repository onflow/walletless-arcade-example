// import ChildAccount from "../../contracts/ChildAccount.cdc"
import ChildAccount from "../../contracts/ChildAuthAccount.cdc"

/// Returns the child address associated with a public key if account
/// was created by the ChildAccountCreator at the specified Address
///
pub fun main(creatorAddress: Address, pubKey: String): Address? {
    // Get a reference to the ChildAccountCreatorPublic Capability from creatorAddress
    if let creatorRef = getAccount(creatorAddress)
        .getCapability<
            &{ChildAccount.ChildAccountCreatorPublic}
        >(
            ChildAccount.ChildAccountCreatorPublicPath
        ).borrow() {
        return creatorRef.getAddressFromPublicKey(publicKey: pubKey)
    }
    return nil
}
