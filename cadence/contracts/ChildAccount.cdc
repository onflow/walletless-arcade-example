import FungibleToken from "./utility/FungibleToken.cdc"
import FlowToken from "./utility/FlowToken.cdc"
import MetadataViews from "./utility/MetadataViews.cdc"

/// This contract is an attempt at establishing and representing a
/// parent-child (AKA puppet or proxy) account hierarchy between accounts.
/// The ChildAccountManager allows a parent account to create child accounts, and
/// maintains a mapping of child accounts as they are created.AccountKey
///
/// An account is deemed a child of a parent if the parent has 1000.0 weight
/// key access to the child account. This means that both the parent's private key
/// and the pairwise private key of the public key provided on creation have access
/// to the accounts created via that ChildAccountManager resource.
///
/// While one generally would not want to share account access with other parties,
/// this can be helpful in a low-stakes environment where the parent account's owner
/// wants to delegate transaction signing to a secondary party. The idea for this setup
/// was born out of pursuit of a more seamless on-chain gameplay UX where a user could
/// let a game client submit transactions on their behalf without signing over the whole
/// of their primary account, and do so in a way that didn't require custom a Capability.
///
/// With that said, users should bare in mind that any assets in a child account incur
/// obvious custody risk, and that it's generally an anti-patter to pass around AuthAccounts.
/// In this case, a user owns both accounts so they are technically passing an AuthAccount
/// to themselves in calls to resources that reside in their own account, so it was deemed
/// a valid application of the pattern.
///
pub contract ChildAccount {

    // TODO:
    // - Events
    // - isCurrentlyActive() to check if originatingPublicKey is revoked on resource.owner

    // Establish metadataview when child account is created
    // - dapp name/publisher name
    // - publisher logo
    // - etc
    // Offer quick utility to bulk move assets between child
    /// Standard canonical path for AuthAccountCapability
    pub let AuthAccountCapabilityPath: CapabilityPath
    pub let ChildAccountManagerStoragePath: StoragePath
    pub let ChildAccountManagerPublicPath: PublicPath
    pub let ChildAccountManagerPrivatePath: PrivatePath
    pub let ChildAccountTagStoragePath: StoragePath
    pub let ChildAccountTagPublicPath: PublicPath
    pub let ChildAccountTagPrivatePath: PrivatePath
    pub let ChildAccountCreatorStoragePath: StoragePath
    pub let ChildAccountCreatorPublicPath: PublicPath


    //check
    /// This should be rather a view (I'm using it as a view)
    ///
    /// Identifies information that could be used to determine the off-chain
    /// associations of a child account
    ///
    pub struct ChildAccountInfo {
        pub let name: String
        pub let description: String
        pub let icon: AnyStruct{MetadataViews.File}
        pub let externalURL: MetadataViews.ExternalURL
        pub let originatingPublicKey: String

        init(
            name: String,
            description: String,
            icon: AnyStruct{MetadataViews.File},
            externalURL: MetadataViews.ExternalURL,
            originatingPublicKey: String
        ) {
            self.name = name
            self.description = description
            self.icon = icon
            self.externalURL = externalURL
            self.originatingPublicKey = originatingPublicKey
        }
    }


    /** --- Child Account Tag--- */
    ///
    ///
    ///
    pub resource interface ChildAccountTagPublic {
        pub var parentAddress: Address?
        pub let address: Address
        pub let info: ChildAccountInfo
        pub fun getGrantedCapabilityTypes(): [Type]
        pub fun isCurrentlyActive(): Bool
    }

    /// Identifies an account as a child account and maintains info
    /// about its parent & association as well as Capabilities granted by
    /// its parent's ChildAccountManager
    ///
    pub resource ChildAccountTag : ChildAccountTagPublic {
        pub var parentAddress: Address?
        pub let address: Address
        pub let info: ChildAccountInfo
        access(contract) let grantedCapabilities: {Type: Capability}
        access(contract) var isActive: Bool

        init(
            parentAddress: Address?,
            address: Address,
            info: ChildAccountInfo
        ) {
            self.parentAddress = parentAddress
            self.address = address
            self.info = info
            self.grantedCapabilities = {}
            self.isActive = true
        }

        /** --- ChildAccountTagPublic --- */
        pub fun getGrantedCapabilityTypes(): [Type] {
            return self.grantedCapabilities.keys
        }
        
        pub fun isCurrentlyActive(): Bool {
            return self.isActive
        }

        /** --- ChildAccountTag --- */

        pub fun getGrantedCapabilityAsRef(_ type: Type): &Capability? {
            pre {
                self.isActive: "ChildAccountTag has been de-permissioned by parent!"
            }
            return &self.grantedCapabilities[type] as &Capability?
        }

        access(contract) fun assignParent(address: Address) {
            pre {
                self.parentAddress == nil:
                    "Parent has already been assigned to this ChildAccountTag as ".concat(self.parentAddress!.toString())
            }
            self.parentAddress = address
        }

        access(contract) fun grantCapability(_ cap: Capability) {
            pre {
                !self.grantedCapabilities.containsKey(cap.getType()):
                    "Already granted Capability of given type!"
            }
            self.grantedCapabilities.insert(key: cap.getType(), cap)
        }

        access(contract) fun revokeCapability(_ type: Type): Capability? {
            return self.grantedCapabilities.remove(key: type)
        }

        access(contract) fun setInactive() {
            self.isActive = false
        }
    }

    /// Wrapper for the child's info and authacct and tag capabilities
    ///
    pub resource ChildAccountController: MetadataViews.Resolver {
        
        access(self) let authAccountCapability: Capability<&AuthAccount>
        access(self) var childAccountTagCapability: Capability<&ChildAccountTag>

        init(
            authAccountCap: Capability<&AuthAccount>,
            childAccountTagCap: Capability<&ChildAccountTag>
        ) {
            self.authAccountCapability = authAccountCap
            self.childAccountTagCapability = childAccountTagCap
        }

        /// Store the child account tag capability
        ///
        pub fun setTagCapability (tagCapability: Capability<&ChildAccountTag>) {
            self.childAccountTagCapability = tagCapability
        }

        /// Function that returns all the Metadata Views implemented by a Child Account controller
        ///
        /// @return An array of Types defining the implemented views. This value will be used by
        ///         developers to know which parameter to pass to the resolveView() method.
        ///
        pub fun getViews(): [Type] {
            return [
                Type<ChildAccount.ChildAccountInfo>()
            ]
        }

        /// Function that resolves a metadata view for this ChildAccount.
        ///
        /// @param view: The Type of the desired view.
        /// @return A structure representing the requested view.
        ///
        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<ChildAccount.ChildAccountInfo>():
                    return self.childAccountTagCapability.borrow()!.info
                default:
                    return nil
            }
        }

        /// Get a reference to the child AuthAccount object.
        /// What is better to do if the capability can not be borrowed? return an optional or just panic?
        ///
        /// We could explore making the account controller a more generic solution (resource interface)
        /// and allow developers to create their own application specific more restricted getters that only expose
        /// specific parts of the account (e.g.: a certain NFT collection). This could not be very useful for the child 
        /// accounts since you will be restricting the highest permission level account access to something it owns, but
        /// could be useful for other forms of delegated access
        ///
        pub fun getAuthAcctRef(): &AuthAccount {
            return self.authAccountCapability.borrow()!
        }

        pub fun getChildTagRef(): &ChildAccountTag {
            return self.childAccountTagCapability.borrow()!
        }

        pub fun getTagPublicRef(): &{ChildAccountTagPublic} {
            return self.childAccountTagCapability.borrow()!
        }
    }

    /* --- ChildAccountCreator --- */

    pub resource interface ChildAccountCreatorPublic {
        pub fun getAddressFromPublicKey (publicKey: String): Address?
    }
    
    /// Anyone holding this resource could create accounts, keeping a mapping of their public keys to their addresses,
    /// and later associate a parent account to any of it, by creating a ChildTagAccount into the previously created 
    /// account and creating a ChildAccountController resource that should be hold by the parent account in a ChildAccountManager
    /// 
    pub resource ChildAccountCreator : ChildAccountCreatorPublic {
        /// mapping of public_key: address
        access(self) let createdChildren: {String: Address}

        init () {
            self.createdChildren = {}
        }

        pub fun getAddressFromPublicKey (publicKey: String): Address? {
            return self.createdChildren[publicKey]
        }
        /// Creates a new account, funding with the signer account, adding the public key
        /// contained in the ChildAccountInfo, and saving a ChildAccountTag with unassigned
        /// parent account containing the provided ChildAccountInfo metadata
        pub fun createChildAccount(
            signer: AuthAccount,
            initialFundingAmount: UFix64,
            childAccountInfo: ChildAccountInfo
        ): AuthAccount {
            
            // Create the child account
            let newAccount = AuthAccount(payer: signer)

            // Create a public key for the proxy account from the passed in string
            let key = PublicKey(
                publicKey: childAccountInfo.originatingPublicKey.decodeHex(),
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

            // Create the ChildAccountTag for the new account
            let childTag <-create ChildAccountTag(
                    parentAddress: nil,
                    address: newAccount.address,
                    info: childAccountInfo
                )
            // Save the ChildAccountTag in the child account's storage & link
            newAccount.save(<-childTag, to: ChildAccount.ChildAccountTagStoragePath)
            newAccount.link<&{ChildAccountTagPublic}>(
                ChildAccount.ChildAccountTagPublicPath,
                target: ChildAccount.ChildAccountTagStoragePath
            )
            newAccount.link<&ChildAccountTag>(
                ChildAccount.ChildAccountTagPrivatePath,
                target: ChildAccount.ChildAccountTagStoragePath
            )

            self.createdChildren.insert(key:childAccountInfo.originatingPublicKey, newAccount.address)

            return newAccount
        }
    }

    /** --- ChildAccountManager --- */

    /// Interface that allows one to view information about the owning account's
    /// child accounts including the addresses for all child accounts and information
    /// about specific child accounts by Address
    ///
    pub resource interface ChildAccountManagerViewer {
        pub fun getChildAccountAddresses(): [Address]
        // TODO: Metadata views collection?
        pub fun getChildAccountInfo(address: Address): ChildAccountInfo?
    }

    /// Resource allows for management of on-chain associations between accounts.
    ///  Note that while creating child accounts
    /// is available in this resource, revoking keys on those child accounts is not.
    /// 
    pub resource ChildAccountManager : ChildAccountManagerViewer {

        pub let childAccounts: @{Address: ChildAccountController}

        init() {
            self.childAccounts <- {}
        }

        /** --- ChildAccountManagerViewer --- */

        /// Returns an array of all child account addresses
        ///
        pub fun getChildAccountAddresses(): [Address] {
            return self.childAccounts.keys
        }
        
        /// Returns ChildAccountInfo struct containing info about the child account
        /// or nil if there is no child account with the given address
        ///
        pub fun getChildAccountInfo(address: Address): ChildAccountInfo? {
            if let controllerRef = self.getChildAccountControllerRef(address: address) {
                return controllerRef.resolveView(Type<ChildAccountInfo>()) as! ChildAccountInfo?
            }
            return nil
        }

        /** --- ChildAccountManager --- */

        /// Allows the ChildAccountManager to retrieve a reference to the ChildAccountController
        /// for a specified child account address
        ///
        /// @param address: The Address of the child account
        ///
        /// @return the reference to the child account's ChildAccountTag
        ///
        pub fun getChildAccountControllerRef(address: Address): &ChildAccountController? {
            return &self.childAccounts[address] as &ChildAccountController?
        }

        pub fun getChildAccountRef(address: Address): &AuthAccount? {
            if let controllerRef = self.getChildAccountControllerRef(address: address) {
                return controllerRef.getAuthAcctRef()
            }
            return nil
        }

        pub fun getChildAccountTagRef(address: Address): &ChildAccountTag? {
            if let controllerRef = self.getChildAccountControllerRef(address: address) {
                return controllerRef.getChildTagRef()
            }
            return nil
        }

        /// Creates a new account, funding with the signer account, adding the public key
        /// contained in the ChildAccountInfo, and linking with this manager's owning
		/// account.
        pub fun createChildAccount(
            signer: AuthAccount,
            initialFundingAmount: UFix64,
            childAccountInfo: ChildAccountInfo,
            authAccountCapPath: CapabilityPath
        ): AuthAccount {
            
            // Create the child account
            let newAccount = AuthAccount(payer: signer)
            // Create a public key for the proxy account from string value in the provided
            // ChildAccountInfo
            let key = PublicKey(
                publicKey: childAccountInfo.originatingPublicKey.decodeHex(),
                signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
            )
            // Add the key to the new account
            newAccount.keys.add(
                publicKey: key,
                hashAlgorithm: HashAlgorithm.SHA3_256,
                weight: 1000.0
            )

            // Get a vault to fund the new account
            let fundingProvider = signer.borrow<
                    &FlowToken.Vault{FungibleToken.Provider}
                >(
                    from: /storage/flowTokenVault
                )!
            // Fund the new account with the initialFundingAmount specified
            newAccount.getCapability<
                    &FlowToken.Vault{FungibleToken.Receiver}
                >(/public/flowTokenReceiver)
                .borrow()!
                .deposit(
                    from: <-fundingProvider.withdraw(
                        amount: initialFundingAmount
                    )
                )

            // Create the ChildAccountTag for the new account
            let childTag <-create ChildAccountTag(
                    parentAddress: self.owner!.address,
                    address: newAccount.address,
                    info: childAccountInfo
                )
            // Save the ChildAccountTag in the child account's storage & link
            newAccount.save(<-childTag, to: ChildAccount.ChildAccountTagStoragePath)
            newAccount.link<&{ChildAccountTagPublic}>(
                ChildAccount.ChildAccountTagPublicPath,
                target: ChildAccount.ChildAccountTagStoragePath
            )
            newAccount.link<&ChildAccountTag>(
                ChildAccount.ChildAccountTagPrivatePath,
                target: ChildAccount.ChildAccountTagStoragePath
            )
            // Get the linked ChildAccountTag Capability
            let tagCapability = newAccount.getCapability<
                    &ChildAccountTag
                >(
                    ChildAccount.ChildAccountTagPrivatePath
                )
            // Link new account's AuthAccountCap
            let childAccountCap: Capability<&AuthAccount> = newAccount.linkAccount(authAccountCapPath)!
            // Create ChildAccountController
            let controller <-create ChildAccountController(
                    authAccountCap: childAccountCap,
                    childAccountTagCap: tagCapability
                )
            // Add the controller to this manager
            self.childAccounts[newAccount.address] <-! controller

            return newAccount
        }

        /// Add an existing account as a child account to this manager resource. This would be done in
        /// a multisig transaction which should be possible if the parent account controls both
        ///
        pub fun addAsChildAccount(childAccountCap: Capability<&AuthAccount>, childAccountInfo: ChildAccountInfo) {
            pre {
                childAccountCap.check():
                    "Problem with given AuthAccount Capability!"
                !self.childAccounts.containsKey(childAccountCap.borrow()!.address):
                    "Child account with given address already exists!"
            }
            // Get a &AuthAccount reference from the the given AuthAccount Capability
            let childAccountRef: &AuthAccount = childAccountCap.borrow()!

            // Check for ChildAccountTag - create, save & link if it doesn't exist
            if childAccountRef.borrow<&ChildAccountTag>(from: ChildAccount.ChildAccountTagStoragePath) == nil {
                // Create ChildAccountTag
                let childTag <-create ChildAccountTag(
                        parentAddress: self.owner!.address,
                        address: childAccountRef.address,
                        info: childAccountInfo
                    )
                // Save the ChildAccountTag in the child account's storage & link
                childAccountRef.save(<-childTag, to: ChildAccount.ChildAccountTagStoragePath)
            }
            // Ensure public Capability linked
            if !childAccountRef.getCapability<&{ChildAccountTagPublic}>(ChildAccount.ChildAccountTagPublicPath).check() {
                childAccountRef.link<&{ChildAccountTagPublic}>(
                    ChildAccount.ChildAccountTagPublicPath,
                    target: ChildAccount.ChildAccountTagStoragePath
                )
            }
            // Ensure private Capability linked
            if !childAccountRef.getCapability<&ChildAccountTag>(ChildAccount.ChildAccountTagPrivatePath).check() {
                childAccountRef.link<&ChildAccountTag>(
                    ChildAccount.ChildAccountTagPrivatePath,
                    target: ChildAccount.ChildAccountTagStoragePath
                )
            }
            // Get a Capability to the linked ChildAccountTag Cap in child's private storage
            let tagCap = childAccountRef
                .getCapability<&
                    ChildAccountTag
                >(
                    ChildAccount.ChildAccountTagPrivatePath
                )
            // Ensure the capability is valid before inserting it in manager's childAccounts mapping
            assert(tagCap.check(), message: "Problem linking ChildAccoutTag Capability in new child account!")
            // Assign the manager's owner as the tag's parentAddress
            tagCap.borrow()!.assignParent(address: self.owner!.address)

            // Create a ChildAccountController & insert to childAccounts mapping
            let controller <-create ChildAccountController(
                    authAccountCap: childAccountCap,
                    childAccountTagCap: tagCap
                )
            self.childAccounts[childAccountRef.address] <-! controller
        }

        /// Adds the given Capability to the ChildAccountTag at the provided Address
        ///
        /// @param to: Address which is the key for the ChildAccountTag Cap
        /// @param cap: Capability to be added to the ChildAccountTag
        ///
        pub fun addCapability(to: Address, _ cap: Capability) {
            pre {
                self.childAccounts.containsKey(to):
                    "No tag with given Address!"
            }
            // Get ref to tag & grant cap
            let tagRef = self.getChildAccountTagRef(
                    address: to
                ) ?? panic("Problem with ChildAccountTag Capability for given address: ".concat(to.toString()))
            tagRef.grantCapability(cap)
        }

        /// Removes the capability of the given type from the ChildAccountTag with the given Address
        ///
        /// @param from: Address indexing the ChildAccountTag Capability
        /// @param type: The Type of Capability to be removed from the ChildAccountTag
        ///
        pub fun removeCapability(from: Address, type: Type) {
            pre {
                self.childAccounts.containsKey(from):
                    "No ChildAccounts with given Address!"
            }
            // Get ref to tag and remove
            let tagRef = self.getChildAccountTagRef(
                    address: from
                ) ?? panic("Problem with ChildAccountTag Capability for given address: ".concat(from.toString()))
            tagRef.revokeCapability(type)
                ?? panic("Capability not properly revoked")
        }

        /// Remove ChildAccountTag, returning its Capability if it exists. Note, doing so
        /// does not revoke the key on the child account if it has been added. This should 
        /// be done in the same transaction in which this method is called.
        ///
        pub fun removeChildAccount(withAddress: Address) {
            if let controller: @ChildAccountController <-self.childAccounts.remove(key: withAddress) {
                // Get a reference to the ChildAccountTag from the Capability
                let tagRef = controller.getChildTagRef()
                // Set the tag as inactive
                tagRef.setInactive()

                // Remove all capabilities from the ChildAccountTag
                for capType in tagRef.getGrantedCapabilityTypes() {
                    tagRef.revokeCapability(capType)
                }
                destroy controller
            }
        }

        destroy () {
            pre {
                self.childAccounts.length == 0:
                    "Attempting to destroy ChildAccountManager with remaining ChildAccountControllers!"
            }
            destroy self.childAccounts
        }
        
    }

    /// Returns true if the provided public key (provided as String) has not been
    /// revoked on the given account address
    pub fun isKeyActiveOnAccount(publicKey: String, address: Address): Bool {
        // Public key strings must have even length
        if publicKey.length % 2 == 0 {
            var keyIndex = 0
            var keysRemain = true
            // Iterate over keys on given account address
            while keysRemain {
                // Get the key as byte array
                if let keyArray = getAccount(address).keys.get(keyIndex: keyIndex)?.publicKey?.publicKey {
                    // Encode the key as a string and compare
                    if publicKey == String.encodeHex(keyArray) {
                        return !getAccount(address).keys.get(keyIndex: keyIndex)!.isRevoked
                    }
                    keyIndex = keyIndex + 1
                } else {
                    keysRemain = false
                }
            }
            return false
        }
        return false
    }

    pub fun createChildAccountManager(): @ChildAccountManager {
        return <-create ChildAccountManager()
    }

    pub fun createChildAccountCreator(): @ChildAccountCreator {
        return <-create ChildAccountCreator()
    }

    init() {
        self.AuthAccountCapabilityPath = /private/AuthAccountCapability
        self.ChildAccountManagerStoragePath = /storage/ChildAccountManager
        self.ChildAccountManagerPublicPath = /public/ChildAccountManager
        self.ChildAccountManagerPrivatePath = /private/ChildAccountManager

        self.ChildAccountTagStoragePath = /storage/ChildAccountTag
        self.ChildAccountTagPublicPath = /public/ChildAccountTag
        self.ChildAccountTagPrivatePath = /private/ChildAccountTag

        self.ChildAccountCreatorStoragePath = /storage/ChildAccountCreator
        self.ChildAccountCreatorPublicPath = /public/ChildAccountCreator
    }
}
 