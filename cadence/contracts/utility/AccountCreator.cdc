import FungibleToken from "./FungibleToken.cdc"
import FlowToken from "./FlowToken.cdc"

/// This contract defines a resource enabling easy account creation and querying of created addresses by their
/// originating public key strings. Note that this contract serves as a utility for prototyping, and its use isn't
/// suggested for production environments for a number of reasons, namely that the resource's mapping isn't
/// scalable for a large number of accounts, passing AuthAccounts is an anti-pattern in Cadence, and this approach is
/// is more inflexible than account creation handled at the transaction level.
///
pub contract AccountCreator {

    /* Canonical paths */
    //
    pub let CreatorStoragePath: StoragePath
    pub let CreatorPublicPath: PublicPath

    /* Events */
    //
    pub event AccountCreated(creatorAddress: Address?, creatorUUID: UInt64, newAccount: Address, originatingPublicKey: String)

    /* --- Creator --- */
    //
    pub resource interface CreatorPublic {
        pub fun getAddressFromPublicKey(publicKey: String): Address?
        pub fun getAllCreatedAddresses(): [Address]
    }

    /// Anyone holding this resource can create new accounts, keeping a mapping of each account's originating public 
    /// keys to their addresses. 
    /// 
    pub resource Creator : CreatorPublic {

        /// mapping of public_key: address
        access(self) let createdAccounts: {String: Address}

        init () {
            self.createdAccounts = {}
        }

        pub fun getAddressFromPublicKey(publicKey: String): Address? {
            return self.createdAccounts[publicKey]
        }

        pub fun getAllCreatedAddresses(): [Address] {
            return self.createdAccounts.values
        }

        /// Creates a new account, funding with the given signer account, adding the provided public key which indexes
        /// the new account address in this Creator's mapping
        ///
        /// **NOTE:** Passing an AuthAccount argument is generally an anti-pattern in Cadence! It's done here for the
        /// sake of prototyping quickly, but generally shouldn't be done in production environments.
        ///
        /// @param signer: The account funding new the new account's creation
        /// @param initialFundingAmount: The amount of additional Flow to add to the new account
        /// @param originatingPublicKey: The public key to add to the new account, for which it's assumed a pairwise
        ///         private key is being managed by the caller
        ///
        /// @return the new account's AuthAccount object
        ///
        pub fun createNewAccount(
            signer: AuthAccount,
            initialFundingAmount: UFix64,
            originatingPublicKey: String
        ): AuthAccount {
            pre {
                !self.createdAccounts.containsKey(originatingPublicKey):
                    "Key has already been used to create an account in this Creator!"
            }
            
            // Create the child account
            let newAccount = AuthAccount(payer: signer)

            // Create a public key for the proxy account from the passed in string
            let key = PublicKey(
                publicKey: originatingPublicKey.decodeHex(),
                signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
            )
            
            //Add the key to the new account
            newAccount.keys.add(
                publicKey: key,
                hashAlgorithm: HashAlgorithm.SHA3_256,
                weight: 1000.0
            )

            // Add some initial funds to the new account, pulled from the signing account.  Amount determined by initialFundingAmount
            newAccount.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
                .borrow()!
                .deposit(
                    from: <- signer.borrow<&{
                        FungibleToken.Provider
                    }>(
                        from: /storage/flowTokenVault
                    )!.withdraw(amount: initialFundingAmount)
                )

            self.createdAccounts.insert(key:originatingPublicKey, newAccount.address)
            emit AccountCreated(creatorAddress: self.owner?.address, creatorUUID: self.uuid, newAccount: newAccount.address, originatingPublicKey: originatingPublicKey)
            return newAccount
        }
    }

    pub fun createNewCreator(): @Creator {
        return <-create Creator()
    }

    init() {
        self.CreatorStoragePath = /storage/AccountCreator
        self.CreatorPublicPath = /public/AccountCreatorPublic
    }
}