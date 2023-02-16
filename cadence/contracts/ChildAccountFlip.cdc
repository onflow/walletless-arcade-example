import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79
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
    }


    /** --- Child Account Tag--- */

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

        /** --- ChildAccountTagPublic --- */
        pub fun getGrantedCapabilityTypes(): [Type]
        
        pub fun isCurrentlyActive(): Bool

        /** --- ChildAccountTag --- */
        pub fun getGrantedCapabilityAsRef(_ type: Type): &Capability? {
            pre {
                self.isActive: "ChildAccountTag has been de-permissioned by parent!"
            }
        }

        access(contract) fun assignParent(address: Address) {
            pre {
                self.parentAddress == nil:
                    "Parent has already been assigned to this ChildAccountTag as ".concat(self.parentAddress!.toString())
            }
        }
        access(contract) fun grantCapability(_ cap: Capability) {
            pre {
                !self.grantedCapabilities.containsKey(cap.getType()):
                    "Already granted Capability of given type!"
            }
        }
        access(contract) fun revokeCapability(_ type: Type): Capability?
        access(contract) fun setInactive()
    }

    /// Wrapper for the child's info and authacct and tag capabilities
    ///
    pub resource ChildAccountController: MetadataViews.Resolver {
        
        access(self) let authAccountCapability: Capability<&AuthAccount>
        access(self) var childAccountTagCapability: Capability<&ChildAccountTag>


        /// Store the child account tag capability
        ///
        pub fun setTagCapability (tagCapability: Capability<&ChildAccountTag>)

        /// Function that returns all the Metadata Views implemented by a Child Account controller
        ///
        /// @return An array of Types defining the implemented views. This value will be used by
        ///         developers to know which parameter to pass to the resolveView() method.
        ///
        pub fun getViews(): [Type]

        /// Function that resolves a metadata view for this ChildAccount.
        ///
        /// @param view: The Type of the desired view.
        /// @return A structure representing the requested view.
        ///
        pub fun resolveView(_ view: Type): AnyStruct?

        /// Get a reference to the child AuthAccount object.
        /// What is better to do if the capability can not be borrowed? return an optional or just panic?
        ///
        /// We could explore making the account controller a more generic solution (resource interface)
        /// and allow developers to create their own application specific more restricted getters that only expose
        /// specific parts of the account (e.g.: a certain NFT collection). This could not be very useful for the child 
        /// accounts since you will be restricting the highest permission level account access to something it owns, but
        /// could be useful for other forms of delegated access
        ///
        pub fun getAuthAcctRef(): &AuthAccount

        pub fun getChildTagRef(): &ChildAccountTag

        pub fun getTagPublicRef(): &{ChildAccountTagPublic}
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

        /// Returns the address of the account created by this resource if it exists
        pub fun getAddressFromPublicKey (publicKey: String): Address?
        /// Creates a new account, funding with the signer account, adding the public key
        /// contained in the ChildAccountInfo, and saving a ChildAccountTag with unassigned
        /// parent account containing the provided ChildAccountInfo metadata
        pub fun createChildAccount(
            signer: AuthAccount,
            initialFundingAmount: UFix64,
            childAccountInfo: ChildAccountInfo
        ): AuthAccount
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

        access(self) let childAccounts: @{Address: ChildAccountController}

        /** --- ChildAccountManagerViewer --- */

        /// Returns an array of all child account addresses
        ///
        pub fun getChildAccountAddresses(): [Address]
        
        /// Returns ChildAccountInfo struct containing info about the child account
        /// or nil if there is no child account with the given address
        ///
        pub fun getChildAccountInfo(address: Address): ChildAccountInfo?

        /** --- ChildAccountManager --- */

        /// Allows the ChildAccountManager to retrieve a reference to the ChildAccountController
        /// for a specified child account address
        ///
        /// @param address: The Address of the child account
        ///
        /// @return the reference to the child account's ChildAccountTag
        ///
        pub fun getChildAccountControllerRef(address: Address): &ChildAccountController?

        pub fun getChildAccountRef(address: Address): &AuthAccount?

        pub fun getChildAccountTagRef(address: Address): &ChildAccountTag?

        /// Add a ChildAccountController to this manager resource
        ///
        // TODO: Remove - I don't think the order of childaccountcontroller before childaccounttag makes
        // sense for this construction - we need the tag to create the controller
        pub fun addChildAccountController(newAccountController: @ChildAccountController, addOwnKey: Bool) {
            pre {
                !self.childAccounts.containsKey(newAccountController.getTagPublicRef().address):
                    "Child account with given address already exists!"
            }
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
        }

        /// Removes the capability of the given type from the ChildAccountTag with the given Address
        ///
        /// @param from: Address indexing the ChildAccountTag Capability
        /// @param type: The Type of Capability to be removed from the ChildAccountTag
        ///
        pub fun removeCapability(from: Address, type: Type)

        /// Remove ChildAccountTag, returning its Capability if it exists. Note, doing so
        /// does not revoke the key on the child account if it has been added. This should 
        /// be done in the same transaction in which this method is called.
        ///
        pub fun removeChildAccount(withAddress: Address)
    }

    pub fun createChildAccountManager(): @ChildAccountManager {
        return <-create ChildAccountManager()
    }


    init() {
        self.AuthAccountCapabilityPath = /private/AuthAccountCapability
        self.ChildAccountManagerStoragePath = /storage/ChildAccountManager
        self.ChildAccountManagerPublicPath = /public/ChildAccountManager
        self.ChildAccountManagerPrivatePath = /private/ChildAccountManager

        self.ChildAccountTagStoragePath = /storage/ChildAccountTag
        self.ChildAccountTagPublicPath = /public/ChildAccountTag
        self.ChildAccountTagPrivatePath = /private/ChildAccountTag
    }
}
 