import "AccountCreator from "../../contracts/utility/AccountCreator.cdc"
import "LinkedAccounts from "../../contracts/LinkedAccounts.cdc"

/// Returns the child address associated with a public key if account was created by the AccountCreator.Creator at the
/// specified Address and the provided public key is still active on the account.
///
pub fun main(creatorAddress: Address, pubKey: String): Address? {
  
  // Get a reference to the CreatorPublic Capability from creatorAddress
  if let creatorRef = getAccount(creatorAddress).getCapability<&AccountCreator.Creator{AccountCreator.CreatorPublic}>(
      AccountCreator.CreatorPublicPath
    ).borrow() {
		// Get the address created by the given public key if it exists
    if let address = creatorRef.getAddressFromPublicKey(publicKey: pubKey) {
			// Also check that the given key has not been revoked
      if LinkedAccounts.isKeyActiveOnAccount(publicKey: pubKey, address: address) {
        return address
      }
    }
    return nil
  }
  return nil
}
 