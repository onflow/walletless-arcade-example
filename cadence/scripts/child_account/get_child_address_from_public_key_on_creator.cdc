import ChildAccount from "../contracts/ChildAccount.cdc"

/// Returns the child address associated with a public key if account
/// was created by the ChildAccountCreator at the specified Address and
/// the provided public key is still active on the account.
///
pub fun main(creatorAddress: Address, pubKey: String): Address? {
  // Get a reference to the ChildAccountCreatorPublic Capability from creatorAddress
  if let creatorRef = getAccount(creatorAddress)
    .getCapability<
      &{ChildAccount.ChildAccountCreatorPublic}
    >(
      ChildAccount.ChildAccountCreatorPublicPath
    ).borrow() {
		// Get the address created by the given public key if it exists
    if let address = creatorRef.getAddressFromPublicKey(publicKey: pubKey) {
			// Also check that the given key has not been revoked
      if ChildAccount.isKeyActiveOnAccount(publicKey: pubKey, address: address) {
        return address
      }
    }
    return nil
  }
  return nil
}