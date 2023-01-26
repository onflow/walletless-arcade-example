const GET_CHILD_ADDRESS_FROM_PUBLIC_KEY = `// import ChildAccount from 0xChildAccount
import ChildAccount from 0xChildAccount

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
`;

export default GET_CHILD_ADDRESS_FROM_PUBLIC_KEY;
