/***************************************************************************

    For more info on this contract & associated transactions & scripts, see:
    https://github.com/onflow/linked-accounts
    
    To provide feedback, check FLIP #72
    https://github.com/onflow/flips/pull/72

****************************************************************************/

import NonFungibleToken from "./utility/NonFungibleToken.cdc"
import ViewResolver from "./utility/ViewResolver.cdc"
import MetadataViews from "./utility/MetadataViews.cdc"
import LinkedAccountMetadataViews from "./LinkedAccountMetadataViews.cdc"

/// This contract establishes a standard set of resources representing linked account associations, enabling
/// querying of either end of account links as well as management of linked accounts, the Capabilities they're
/// granted, as well as addition/removal of new/existing account delegations. By leveraging this contract, a new sort
/// of custody is unlocked - Hybrid Custody - enabling the mainstream-friendly walletless onboarding UX we're so
/// excited about on Flow.
///
/// By leveraging existing metadata standards, builders can easily query a Collection's linked accounts, their
/// relevant metadata, etc. With implementation of the NFT standard, Collection owners can easily transfer delegation
/// they wish in a mental model that's familiar and easy to understand.
///
/// The Collection allows a main account to add linked accounts, and An account is deemed a child of a
/// parent if the parent maintains delegated access on the child account by way of AuthAccount
/// Capability wrapped in an NFT and saved in a Collection. By
/// the constructs defined in this contract, a linked account can be identified by a stored
/// Handler.
///
/// While one generally would not want to share account access with other parties, this can be helpful in a low-stakes
/// environment where the parent account's owner wants to delegate transaction signing to a secondary party. The idea 
/// for this setup was born out of pursuit of a more seamless on-chain gameplay UX where a user could let a game client
/// submit transactions on their behalf without signing over the whole of their primary account, and do so in a way
/// that didn't require custom a Capability.
///
/// With that said, users should bear in mind that any assets in a linked account incur obvious custodial risk, and
/// that it's generally an anti-pattern to pass around AuthAccounts. In this case, a user owns both accounts so they
/// are technically passing an AuthAccount to themselves in calls to resources that reside in their own account, so 
/// it was deemed a valid application of the pattern. That said, a user should be cognizant of the party with key
/// access on the linked account as this pattern requires some degree of trust in the custodying party.
///
pub contract LinkedAccounts : NonFungibleToken, ViewResolver {

    /// The number of NFTs in existence
    pub var totalSupply: UInt64

    // NFT conforming events
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    
    // LinkedAccounts Events
    pub event MintedNFT(id: UInt64, parent: Address, child: Address)
    pub event AddedLinkedAccount(parent: Address, child: Address, nftID: UInt64)
    pub event UpdatedLinkedAccountParentAddress(previousParent: Address, newParent: Address, child: Address)
    pub event UpdatedAuthAccountCapabilityForLinkedAccount(id: UInt64, parent: Address, child: Address)
    pub event LinkedAccountGrantedCapability(parent: Address, child: Address, capabilityType: Type)
    pub event RevokedCapabilitiesFromLinkedAccount(parent: Address, child: Address, capabilityTypes: [Type])
    pub event RemovedLinkedAccount(parent: Address, child: Address)
    pub event CollectionCreated()

    // Canonical paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let CollectionPrivatePath: PrivatePath
    pub let HandlerStoragePath: StoragePath
    pub let HandlerPublicPath: PublicPath
    pub let HandlerPrivatePath: PrivatePath

    /** --- Handler --- */
    //
    pub resource interface HandlerPublic {
        pub fun getParentAddress(): Address
        pub fun getGrantedCapabilityTypes(): [Type]
        pub fun isCurrentlyActive(): Bool
    }

    /// Identifies an account as a child account and maintains info about its parent & association as well as
    /// Capabilities granted by its parent account's Collection
    ///
    pub resource Handler : HandlerPublic, MetadataViews.Resolver {
        /// Pointer to this account's parent account
        access(contract) var parentAddress: Address
        /// The address of the account where the ccountHandler resource resides
        access(contract) let address: Address
        /// Metadata about the purpose of this child account guarantees standard minimum metadata is stored
        /// about linked accounts
        access(contract) let metadata: AnyStruct{LinkedAccountMetadataViews.AccountMetadata}
        /// Resolver struct to increase the flexibility, allowing implementers to resolve their own structs
        access(contract) let resolver: AnyStruct{LinkedAccountMetadataViews.MetadataResolver}?
        /// Capabilities that have been granted by the parent account
        access(contract) let grantedCapabilities: {Type: Capability}
        /// Flag denoting whether link to parent is still active
        access(contract) var isActive: Bool

        init(
            parentAddress: Address,
            address: Address,
            metadata: AnyStruct{LinkedAccountMetadataViews.AccountMetadata},
            resolver: AnyStruct{LinkedAccountMetadataViews.MetadataResolver}?
        ) {
            self.parentAddress = parentAddress
            self.address = address
            self.metadata = metadata
            self.grantedCapabilities = {}
            self.resolver = resolver
            self.isActive = true
        }

        /// Returns the metadata view types supported by this Handler
        ///
        /// @return An array of metadata view types
        ///
        pub fun getViews(): [Type] {
            let views: [Type] = []
            if self.resolver != nil {
                views.appendAll(self.resolver!.getViews())
            }
            views.appendAll([
                Type<LinkedAccountMetadataViews.AccountInfo>(),
                Type<MetadataViews.Display>()
            ])
            if self.metadata.getType() != Type<LinkedAccountMetadataViews.AccountInfo>() {
                views.append(self.metadata.getType())
            }
            return views
        }
        
        /// Returns the requested view if supported or nil otherwise
        ///
        /// @param view: The Type of metadata struct requests
        ///
        /// @return The metadata of requested Type if supported and nil otherwise
        ///
        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<LinkedAccountMetadataViews.AccountInfo>():
                    return LinkedAccountMetadataViews.AccountInfo(
                        name: self.metadata.name,
                        description: self.metadata.description,
                        thumbnail: self.metadata.thumbnail,
                        externalURL: self.metadata.externalURL
                    )
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.metadata.name,
                        description: self.metadata.description,
                        thumbnail: self.metadata.thumbnail
                    )
                case self.metadata.getType():
                    return self.metadata
                default:
                    if self.resolver != nil && self.resolver!.getViews().contains(view) {
                        return self.resolver!.resolveView(view)
                    }
                    return nil
            }
        }

        pub fun getAddress(): Address {
            pre {
                self.owner != nil:
                    "This Handler does not currently reside within an account!"
            }
            post {
                result == self.owner!.address:
                    "This Handler is not located in the correct linked account!"
            }
            return self.address
        }

        /// Returns the Address of this linked account's parent Collection
        ///
        pub fun getParentAddress(): Address {
            return self.parentAddress
        }
        
        /// Returns the metadata related to this account's association
        ///
        pub fun getAccountMetadata(): AnyStruct{LinkedAccountMetadataViews.AccountMetadata} {
            return self.metadata
        }

        /// Returns the optional resolver contained within this Handler
        ///
        pub fun getResolver(): AnyStruct{LinkedAccountMetadataViews.MetadataResolver}? {
            return self.resolver
        }

        /// Returns the types of Capabilities this Handler has been granted
        ///
        /// @return An array of the Types of Capabilities this resource has access to in its grantedCapabilities
        ///         mapping
        ///
        pub fun getGrantedCapabilityTypes(): [Type] {
            return self.grantedCapabilities.keys
        }
        
        /// Returns whether the link between this Handler and its associated Collection is still active - in
        /// practice whether the linked Collection has removed this Handler's Capability
        ///
        pub fun isCurrentlyActive(): Bool {
            return self.isActive
        }

        /// Retrieves a granted Capability as a reference or nil if it does not exist.
        /// 
        //  **Note**: This is a temporary solution for Capability auditing & easy revocation 
        /// their way to Cadence, enabling a parent account to issue, audit and easily revoke Capabilities to linked
        /// accounts.
        /// 
        /// @param type: The Type of Capability being requested
        ///
        /// @return A reference to the Capability or nil if a Capability of given Type is not
        ///         available
        ///
        pub fun getGrantedCapabilityAsRef(_ type: Type): &Capability? {
            pre {
                self.isActive: "LinkedAccounts.Handler has been de-permissioned by parent!"
            }
            return &self.grantedCapabilities[type] as &Capability?
        }

        /// Updates this Handler's parentAddress, occurring whenever a corresponding NFT transfer occurs
        ///
        /// @param newAddress: The Address of the new parent account
        ///
        access(contract) fun updateParentAddress(_ newAddress: Address) {
            self.parentAddress = newAddress
        }

        /// Inserts the given Capability into this Handler's grantedCapabilities mapping.
        ///
        /// @param cap: The Capability being granted
        ///
        access(contract) fun grantCapability(_ cap: Capability) {
            pre {
                !self.grantedCapabilities.containsKey(cap.getType()):
                    "Already granted Capability of given type!"
            }
            self.grantedCapabilities.insert(key: cap.getType(), cap)
        }

        /// Removes the Capability of given Type from this Handler's grantedCapabilities mapping.
        ///
        /// @param type: The Type of Capability to be removed
        ///
        /// @return the removed Capability or nil if it did not exist
        ///
        access(contract) fun revokeCapabilities(_ types: [Type]): [Type] {
            // return self.grantedCapabilities.remove(key: type)
            let removedTypes: [Type] = []
            for capType in types {
                if let removed = self.grantedCapabilities.remove(key: capType) {
                    removedTypes.append(removed.getType())
                }
            }
            return removedTypes
        }

        /// Removes all granted Capabilities from this Handler's grantedCapabilities mapping. Helpful when removing
        /// a Handler association from a Collection (AKA unlinking an account) as well as limiting the number of events
        /// emitted compared to revoking one-by-one.
        ///
        /// @return An array containing the types of all Capabilities removed
        ///
        access(contract) fun revokeAllCapabilities(): [Type] {
            return self.revokeCapabilities(self.grantedCapabilities.keys)
        }

        /// Sets the isActive Bool flag to false
        ///
        access(contract) fun setInactive() {
            self.isActive = false
        }
    }

    /** --- NFT --- */
    //
    /// Publicly accessible Capability for linked account wrapping resource, protecting the wrapped Capabilities
    /// from public access via reference as implemented in LinkedAccount.NFT
    ///
    pub resource interface NFTPublic {
        pub let id: UInt64
        pub fun checkAuthAccountCapability(): Bool
        pub fun checkHandlerCapability(): Bool
        pub fun getChildAccountAddress(): Address
        pub fun getParentAccountAddress(): Address
        pub fun getHandlerPublicRef(): &Handler{HandlerPublic}
    }

    /// Wrapper for the linked account's metadata, AuthAccount, and Handler Capabilities
    /// implemented as an NFT
    ///
    pub resource NFT : NFTPublic, NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        access(self) var parentAddress: Address
        access(self) let linkedAccountAddress: Address
        /// The AuthAccount Capability for the linked account this NFT represents
        access(self) var authAccountCapability: Capability<&AuthAccount>
        /// Capability for the relevant Handler
        access(self) var handlerCapability: Capability<&Handler>

        init(
            authAccountCap: Capability<&AuthAccount>,
            handlerCap: Capability<&Handler>
        ) {
            pre {
                authAccountCap.borrow() != nil:
                    "Problem with provided AuthAccount Capability"
                handlerCap.borrow() != nil:
                    "Problem with provided Handler Capability"
                authAccountCap.borrow()!.address == handlerCap.address &&
                handlerCap.address == handlerCap.borrow()!.getAddress():
                    "Addresses among both Capabilities do not match!"
            }
            self.id = self.uuid
            self.parentAddress = handlerCap.borrow()!.getParentAddress()
            self.linkedAccountAddress = authAccountCap.borrow()!.address
            self.authAccountCapability = authAccountCap
            self.handlerCapability = handlerCap
        }

        /// Function that returns all the Metadata Views implemented by an NFT & by extension the relevant Handler
        ///
        /// @return An array of Types defining the implemented views. This value will be used by developers to know
        ///         which parameter to pass to the resolveView() method.
        ///
        pub fun getViews(): [Type] {
            let handlerRef: &LinkedAccounts.Handler = self.getHandlerRef()
            let views = handlerRef.getViews()
            views.appendAll([
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.NFTView>(),
                Type<MetadataViews.Display>()
            ])
            return views
        }

        /// Function that resolves a metadata view for this ChildAccount.
        ///
        /// @param view: The Type of the desired view.
        ///
        /// @return A struct representing the requested view.
        ///
        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.NFTCollectionData>():
                    return LinkedAccounts.resolveView(view)
                case Type<MetadataViews.NFTCollectionDisplay>():
                    return LinkedAccounts.resolveView(view)
                case Type<MetadataViews.NFTView>():
                    let handlerRef = self.getHandlerRef()
                    let accountInfo = (handlerRef.resolveView(
                            Type<LinkedAccountMetadataViews.AccountInfo>()) as! LinkedAccountMetadataViews.AccountInfo?
                        )!
                    return MetadataViews.NFTView(
                        id: self.id,
                        uuid: self.uuid,
                        display: handlerRef.resolveView(Type<MetadataViews.Display>()) as! MetadataViews.Display?,
                        externalURL: accountInfo.externalURL,
                        collectionData: LinkedAccounts.resolveView(Type<MetadataViews.NFTCollectionData>()) as! MetadataViews.NFTCollectionData?,
                        collectionDisplay: LinkedAccounts.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) as! MetadataViews.NFTCollectionDisplay?,
                        royalties: nil,
                        traits: MetadataViews.dictToTraits(
                                dict: {
                                    "id": self.id,
                                    "parentAddress": handlerRef.parentAddress,
                                    "linkedAddress": handlerRef.address,
                                    "creationTimestamp": accountInfo.creationTimestamp
                                },
                                excludedNames: nil
                            )
                    )
                case Type<MetadataViews.Display>():
                    return self.getHandlerRef().resolveView(Type<MetadataViews.Display>())
                default:
                    let handlerRef: &LinkedAccounts.Handler = self.handlerCapability.borrow()
                    ?? panic("Problem with Handler Capability in this NFT")
                    return handlerRef.resolveView(view)
            }
        }

        /// Get a reference to the child AuthAccount object.
        ///
        pub fun getAuthAcctRef(): &AuthAccount {
            return self.authAccountCapability.borrow() ?? panic("Problem with AuthAccount Capability in NFT!")
        }

        /// Returns a reference to the Handler
        ///
        pub fun getHandlerRef(): &Handler {
            return self.handlerCapability.borrow() ?? panic("Problem with LinkedAccounts.Handler Capability in NFT!")
        }

        /// Returns whether AuthAccount Capability link is currently active
        ///
        /// @return True if the link is active, false otherwise
        ///
        pub fun checkAuthAccountCapability(): Bool {
            return self.authAccountCapability.check()
        }

        /// Returns whether Handler Capability link is currently active
        ///
        /// @return True if the link is active, false otherwise
        ///
        pub fun checkHandlerCapability(): Bool {
            return self.handlerCapability.check()
        }

        /// Returns the child account address this NFT manages a Capability for
        ///
        /// @return the address of the account this NFT has delegated access to
        ///
        pub fun getChildAccountAddress(): Address {
            return self.getAuthAcctRef().address
        }

        /// Returns the address on the parent side of the account link
        ///
        /// @return the address of the account that has been given delegated access
        ///
        pub fun getParentAccountAddress(): Address {
            return self.parentAddress
        }

        /// Returns a reference to the Handler as HandlerPublic
        ///
        /// @return a reference to the Handler as HandlerPublic 
        ///
        pub fun getHandlerPublicRef(): &Handler{HandlerPublic} {
            return self.handlerCapability.borrow() ?? panic("Problem with Handler Capability in NFT!")
        }

        /// Updates this NFT's AuthAccount Capability to another for the same account. Useful in the event the
        /// Capability needs to be retargeted
        ///
        /// @param new: The new AuthAccount Capability, but must be for the same account as the current Capability
        ///
        pub fun updateAuthAccountCapability(_ newCap: Capability<&AuthAccount>) {
            pre {
                newCap.check(): "Problem with provided Capability"
                newCap.borrow()!.address == self.linkedAccountAddress:
                    "Provided AuthAccount is not for this NFT's associated account Address!"
            }
            self.authAccountCapability = newCap
            emit UpdatedAuthAccountCapabilityForLinkedAccount(id: self.id, parent: self.parentAddress, child: self.linkedAccountAddress)
        }

        /// Updates this NFT's AuthAccount Capability to another for the same account. Useful in the event the
        /// Capability needs to be retargeted
        ///
        /// @param new: The new AuthAccount Capability, but must be for the same account as the current Capability
        ///
        pub fun updateHandlerCapability(_ newCap: Capability<&Handler>) {
            pre {
                newCap.check(): "Problem with provided Capability"
                newCap.borrow()!.address == self.linkedAccountAddress &&
                newCap.address == self.linkedAccountAddress:
                    "Provided AuthAccount is not for this NFT's associated account Address!"
            }
            self.handlerCapability = newCap
        }

        /// Updates this NFT's parent address & the parent address of the associated Handler
        ///
        /// @param newAddress: The address of the new parent account
        ///
        access(contract) fun updateParentAddress(_ newAddress: Address) {
            // Check if new parent address differs from current
            if newAddress != self.parentAddress {
                // Get the existing parent address
                let previousParent: Address = self.parentAddress
                // Reassign to new address
                self.parentAddress = newAddress
                // Update in Handler as well & emit
                self.getHandlerRef().updateParentAddress(newAddress)
                emit UpdatedLinkedAccountParentAddress(previousParent: previousParent, newParent: newAddress, child: self.linkedAccountAddress)
            }
        }
    }

    /** --- Collection --- */
    //
    /// Interface that allows one to view information about the owning account's
    /// child accounts including the addresses for all child accounts and information
    /// about specific child accounts by Address
    ///
    pub resource interface CollectionPublic {
        pub fun getAddressToID(): {Address: UInt64}
        pub fun getLinkedAccountAddresses(): [Address]
        pub fun getIDOfNFTByAddress(address: Address): UInt64?
        pub fun getIDs(): [UInt64]
        pub fun isLinkActive(onAddress: Address): Bool
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            post {
                result.id == id: "The returned reference's ID does not match the requested ID"
            }
        }
        pub fun borrowNFTSafe(id: UInt64): &NonFungibleToken.NFT? {
            post {
                result == nil || result!.id == id: "The returned reference's ID does not match the requested ID"
            }
        }
        pub fun borrowLinkedAccountsNFTPublic(id: UInt64): &LinkedAccounts.NFT{LinkedAccounts.NFTPublic}? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow ExampleNFT reference: the ID of the returned reference is incorrect"
            }
        }
        pub fun borrowViewResolverFromAddress(address: Address): &{MetadataViews.Resolver}
    }

    /// A Collection of LinkedAccounts.NFTs, maintaining all delegated AuthAccount & Handler Capabilities in NFTs.
    /// One NFT (representing delegated account access) per linked account can be maintained in this Collection,
    /// enabling public view Capabilities and owner-related management methods, including removing linked accounts, as
    /// well as granting & revoking Capabilities. 
    /// 
    pub resource Collection : CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        /// Mapping of contained LinkedAccount.NFTs as NonFungibleToken.NFTs
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
        /// Mapping linked account Address to relevant NFT.id
        pub let addressToID: {Address: UInt64}

        init() {
            self.ownedNFTs <-{}
            self.addressToID = {}
        }

        /// Returns the NFT as a Resolver for the specified ID
        ///
        /// @param id: The id of the NFT
        ///
        /// @return A reference to the NFT as a Resolver
        ///
        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver} {
            let nft = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT?
                ?? panic("Collection does not have NFT with specified ID")
            let castNFT = nft as! &LinkedAccounts.NFT
            return castNFT as &AnyResource{MetadataViews.Resolver}
        }

        /// Returns the IDs of the NFTs in this Collection
        ///
        /// @return an array of the contained NFT resources
        ///
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        /// Returns a reference to the specified NonFungibleToken.NFT with given ID
        ///
        /// @param id: The id of the requested NonFungibleToken.NFT
        ///
        /// @return The requested NonFungibleToken.NFT, panicking if there is not an NFT with requested id in this
        ///         Collection
        ///
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT? ?? panic("Collection does not have NFT with specified ID")
        }

        /// Returns a reference to the specified NonFungibleToken.NFT with given ID or nil
        ///
        /// @param id: The id of the requested NonFungibleToken.NFT
        ///
        /// @return The requested NonFungibleToken.NFT or nil if there is not an NFT with requested id in this
        ///         Collection
        ///
        pub fun borrowNFTSafe(id: UInt64): &NonFungibleToken.NFT? {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT?
        }
        
        /// Returns a reference to the specified LinkedAccounts.NFT as NFTPublic with given ID or nil
        ///
        /// @param id: The id of the requested LinkedAccounts.NFT as NFTPublic
        ///
        /// @return The requested LinkedAccounts.NFTublic or nil if there is not an NFT with requested id in this
        ///         Collection
        ///
        pub fun borrowLinkedAccountsNFTPublic(id: UInt64): &LinkedAccounts.NFT{LinkedAccounts.NFTPublic}? {
            if let nft = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT? {
                let castNFT = nft as! &LinkedAccounts.NFT
                return castNFT as &LinkedAccounts.NFT{LinkedAccounts.NFTPublic}?
            }
            return nil
        }

        /// Returns whether this Collection has an active link for the given address.
        ///
        /// @return True if there is an NFT in this collection associated with the given address that has active
        /// AuthAccount & Handler Capabilities and a Handler in the linked account that is set as active
        ///
        pub fun isLinkActive(onAddress: Address): Bool {
            if let nftRef = self.borrowLinkedAccountNFT(address: onAddress) {
                return nftRef.checkAuthAccountCapability() &&
                    nftRef.checkHandlerCapability() &&
                    nftRef.getHandlerRef().isCurrentlyActive()
            }
            return false
        }

        /// Takes a given NonFungibleToken.NFT and adds it to this Collection's mapping of ownedNFTs, emitting both
        /// Deposit and AddedLinkedAccount since depositing LinkedAccounts.NFT is effectively giving a Collection owner
        /// delegated access to an account
        ///
        /// @param token: NonFungibleToken.NFT to be deposited to this Collection
        ///
        pub fun deposit(token: @NonFungibleToken.NFT) {
            pre {
                !self.ownedNFTs.containsKey(token.id):
                    "Collection already contains NFT with id: ".concat(token.id.toString())
                self.owner!.address != nil:
                    "Cannot transfer LinkedAccount.NFT to unknown party!"
            }
            // Assign scoped variables from LinkedAccounts.NFT
            let token <- token as! @LinkedAccounts.NFT
            let ownerAddress: Address = self.owner!.address
            let linkedAccountAddress: Address = token.getChildAccountAddress()
            let id: UInt64 = token.id

            // Ensure this Collection does not already have a LinkedAccounts.NFT for this token's account
            assert(
                !self.addressToID.containsKey(linkedAccountAddress),
                message: "Already have delegated access to account address: ".concat(linkedAccountAddress.toString())
            )

            // Update the NFT's parentAddress if needed
            token.updateParentAddress(ownerAddress)

            // Add the new token to the ownedNFTs & addressToID mappings
            let oldToken <- self.ownedNFTs[id] <- token
            self.addressToID.insert(key: linkedAccountAddress, id)
            destroy oldToken

            // Ensure both sides of account link have been properly labeled in the deposited NFT
            let depositedNFTRef: &NFT = self.borrowLinkedAccountNFT(address: linkedAccountAddress)!
            assert(
                depositedNFTRef.getParentAccountAddress() == self.owner!.address,
                message: "Problem assigning parent/child addresses to NFT while depositing!"
            )
            assert(
                self.addressToID[linkedAccountAddress] == id,
                message: "Problem associating LinkedAccounts.NFT account Address to NFT.id"
            )

            // Emit events
            emit Deposit(id: id, to: ownerAddress)
            emit AddedLinkedAccount(parent: ownerAddress, child: linkedAccountAddress, nftID: id)
        }
        
        /// Withdraws the LinkedAccounts.NFT with the given id as a NonFungibleToken.NFT, emitting standard Withdraw
        /// event along with RemovedLinkedAccount event, denoting the delegated access for the account associated with
        /// the NFT has been removed from this Collection
        ///
        /// @param withdrawID: The id of the requested NFT
        ///
        /// @return The requested LinkedAccounts.NFT as a NonFungibleToken.NFT
        ///
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            pre {
                self.ownedNFTs.containsKey(withdrawID):
                    "Collection does not contain NFT with given id: ".concat(withdrawID.toString())
                self.owner!.address != nil:
                    "Cannot withdraw LinkedAccount.NFT from unknown party!"
            }
            post {
                result.id == withdrawID:
                    "Incorrect NFT withdrawn from Collection!"
                !self.ownedNFTs.containsKey(withdrawID):
                    "Collection still contains NFT with requested ID!"
            }
            // Get the token from the ownedNFTs mapping
            let token: @NonFungibleToken.NFT <- self.ownedNFTs.remove(key: withdrawID)!

            // Get the Address associated with the withdrawing token id
            let childAddress: Address = self.addressToID.keys[
                    self.addressToID.values.firstIndex(of: withdrawID)!
                ]
            // Remove the address entry in our secondary mapping
            self.addressToID.remove(key: childAddress)!

            // Emit events & return
            emit Withdraw(id: token.id, from: self.owner?.address)
            emit RemovedLinkedAccount(parent: self.owner!.address, child: childAddress)
            return <-token
        }

        /// Withdraws the LinkedAccounts.NFT with the given Address as a NonFungibleToken.NFT, emitting standard 
        /// Withdraw event along with RemovedLinkedAccount event, denoting the delegated access for the account
        /// associated with the NFT has been removed from this Collection
        ///
        /// @param address: The Address associated with the requested NFT
        ///
        /// @return The requested LinkedAccounts.NFT as a NonFungibleToken.NFT
        ///
        pub fun withdrawByAddress(address: Address): @NonFungibleToken.NFT {
            // Get the id of the assocated NFT
            let id: UInt64 = self.getIDOfNFTByAddress(address: address)
                ?? panic("This Collection does not contain an NFT associated with the given address ".concat(address.toString()))
            // Withdraw & return the NFT
            return <- self.withdraw(withdrawID: id)
        }

        /// Getter method to make indexing linked account Addresses to relevant NFT.ids easy
        ///
        /// @return This collection's addressToID mapping, identifying a linked account's associated NFT.id
        ///
        pub fun getAddressToID(): {Address: UInt64} {
            return self.addressToID
        }

        /// Returns an array of all child account addresses
        ///
        /// @return an array containing the Addresses of the linked accounts
        ///
        pub fun getLinkedAccountAddresses(): [Address] {
            let addressToIDRef = &self.addressToID as &{Address: UInt64}
            return addressToIDRef.keys
        }

        /// Returns the id of the associated NFT wrapping the AuthAccount Capability for the given
        /// address
        ///
        /// @param ofAddress: Address associated with the desired LinkedAccounts.NFT
        ///
        /// @return The id of the associated LinkedAccounts.NFT or nil if it does not exist in this Collection
        ///
        pub fun getIDOfNFTByAddress(address: Address): UInt64? {
            let addressToIDRef = &self.addressToID as &{Address: UInt64}
            return addressToIDRef[address]
        }

        /// Returns a reference to the NFT as a Resolver based on the given address
        ///
        /// @param address: The address of the linked account
        ///
        /// @return A reference to the NFT as a Resolver
        ///
        pub fun borrowViewResolverFromAddress(address: Address): &{MetadataViews.Resolver} {
            return self.borrowViewResolver(
                id: self.addressToID[address] ?? panic("No LinkedAccounts.NFT with given Address")
            )
        }

        /// Allows the Collection to retrieve a reference to the NFT for a specified child account address
        ///
        /// @param address: The Address of the child account
        ///
        /// @return the reference to the child account's Handler
        ///
        pub fun borrowLinkedAccountNFT(address: Address): &LinkedAccounts.NFT? {
            let addressToIDRef = &self.addressToID as &{Address: UInt64}
            if let id: UInt64 = addressToIDRef[address] {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &LinkedAccounts.NFT
            }
            return nil
        }

        /// Returns a reference to the specified linked account's AuthAccount
        ///
        /// @param address: The address of the relevant linked account
        ///
        /// @return the linked account's AuthAccount as ephemeral reference or nil if the
        ///         address is not of a linked account
        ///
        pub fun getChildAccountRef(address: Address): &AuthAccount? {
            if let ref = self.borrowLinkedAccountNFT(address: address) {
                return ref.getAuthAcctRef()
            }
            return nil
        }

        /// Returns a reference to the specified linked account's Handler
        ///
        /// @param address: The address of the relevant linked account
        ///
        /// @return the child account's Handler as ephemeral reference or nil if the
        ///         address is not of a linked account
        ///
        pub fun getHandlerRef(address: Address): &Handler? {
            if let ref = self.borrowLinkedAccountNFT(address: address) {
                return ref.getHandlerRef()
            }
            return nil
        }

        /// Add an existing account as a linked account to this Collection. This would be done in either a multisig
        /// transaction or by the linking account linking & publishing its AuthAccount Capability for the Collection's
        /// owner.
        ///
        /// @param childAccountCap: AuthAccount Capability for the account to be added as a child account
        /// @param childAccountInfo: Metadata struct containing relevant data about the account being linked
        ///
        pub fun addAsChildAccount(
            linkedAccountCap: Capability<&AuthAccount>,
            linkedAccountMetadata: AnyStruct{LinkedAccountMetadataViews.AccountMetadata},
            linkedAccountMetadataResolver: AnyStruct{LinkedAccountMetadataViews.MetadataResolver}?,
            handlerPathSuffix: String
        ) {
            pre {
                linkedAccountCap.check():
                    "Problem with given AuthAccount Capability!"
                !self.addressToID.containsKey(linkedAccountCap.borrow()!.address):
                    "Collection already has LinkedAccount.NFT for given account!"
                self.owner != nil:
                    "Cannot add a linked account without an owner for this Collection!"
            }

            /** --- Assign account variables --- */
            //
            // Get a &AuthAccount reference from the the given AuthAccount Capability
            let linkedAccountRef: &AuthAccount = linkedAccountCap.borrow()!
            // Assign parent & child address to identify sides of the link
            let childAddress: Address = linkedAccountRef.address
            let parentAddress: Address = self.owner!.address

            /** --- Path construction & validation --- */
            //
            // Construct paths for the Handler & its Capabilities
            let handlerStoragePath: StoragePath = StoragePath(identifier: handlerPathSuffix)
                ?? panic("Could not construct StoragePath for Handler with given suffix")
            let handlerPublicPath: PublicPath = PublicPath(identifier: handlerPathSuffix)
                ?? panic("Could not construct PublicPath for Handler with given suffix")
            let handlerPrivatePath: PrivatePath = PrivatePath(identifier: handlerPathSuffix)
                ?? panic("Could not construct PrivatePath for Handler with given suffix")
            // Ensure nothing saved at expected paths
            assert(
                linkedAccountRef.type(at: handlerStoragePath) == nil,
                message: "Linked account already has stored object at: ".concat(handlerStoragePath.toString())
            )
            assert(
                linkedAccountRef.getLinkTarget(handlerPublicPath) == nil,
                message: "Linked account already has public Capability at: ".concat(handlerPublicPath.toString())
            )
            assert(
                linkedAccountRef.getLinkTarget(handlerPrivatePath) == nil,
                message: "Linked account already has private Capability at: ".concat(handlerPrivatePath.toString())
            )

            /** --- Configure newly linked account with Handler & get Capability --- */
            //
            // Create a Handler
            let handler: @LinkedAccounts.Handler <-create Handler(
                    parentAddress: parentAddress,
                    address: childAddress,
                    metadata: linkedAccountMetadata,
                    resolver: linkedAccountMetadataResolver
                )
            // Save the Handler in the child account's storage & link
            linkedAccountRef.save(<-handler, to: handlerStoragePath)
            // Ensure public Capability linked
            linkedAccountRef.link<&Handler{HandlerPublic}>(
                handlerPublicPath,
                target: handlerStoragePath
            )
            // Ensure private Capability linked
            linkedAccountRef.link<&Handler>(
                handlerPrivatePath,
                target: handlerStoragePath
            )
            // Get a Capability to the linked Handler Cap in linked account's private storage
            let handlerCap: Capability<&LinkedAccounts.Handler> = linkedAccountRef.getCapability<&Handler>(
                    handlerPrivatePath
                )
            // Ensure the capability is valid before inserting it in collection's linkedAccounts mapping
            assert(handlerCap.check(), message: "Problem linking Handler Capability in new child account at PrivatePath!")

            /** --- Wrap caps in newly minted NFT & deposit --- */
            //
            // Create an NFT, increment supply, & deposit to this Collection before emitting MintedNFT
            let nft <-LinkedAccounts.mintNFT(
                    authAccountCap: linkedAccountCap,
                    handlerCap: handlerCap
                )
            let nftID: UInt64 = nft.id
            LinkedAccounts.totalSupply = LinkedAccounts.totalSupply + 1
            emit MintedNFT(id: nftID, parent: parentAddress, child: childAddress)
            self.deposit(token: <-nft)
        }

        /// Adds the given Capability to the Handler at the provided Address
        ///
        /// @param to: Address which is the key for the Handler Cap
        /// @param cap: Capability to be added to the Handler
        ///
        pub fun addCapability(to: Address, _ cap: Capability) {
            pre {
                self.addressToID.containsKey(to):
                    "No linked account NFT with given Address!"
            }
            // Get ref to handler
            let handlerRef = self.getHandlerRef(
                    address: to
                ) ?? panic("Problem with Handler Capability for given address: ".concat(to.toString()))
            let capType: Type = cap.getType()
            
            // Pass the Capability to the linked account via the handler & emit
            handlerRef.grantCapability(cap)
            emit LinkedAccountGrantedCapability(parent: self.owner!.address, child: to, capabilityType: capType)
        }

        /// Removes the capability of the given type from the Handler with the given Address
        ///
        /// @param from: Address indexing the Handler Capability
        /// @param type: The Type of Capability to be removed from the Handler
        ///
        pub fun removeCapabilities(from: Address, types: [Type]): [Type] {
            pre {
                self.addressToID.containsKey(from):
                    "No linked account with given Address!"
            }
            // Get ref to handler and remove
            let handlerRef: &LinkedAccounts.Handler = self.getHandlerRef(
                    address: from
                ) ?? panic("Problem with Handler Capability for given address: ".concat(from.toString()))
            // Revoke Capability & emit
            let removedTypes: [Type] = handlerRef.revokeCapabilities(types)
            emit RevokedCapabilitiesFromLinkedAccount(parent: self.owner!.address, child: from, capabilityTypes: types)
            return removedTypes
        }

        /// Remove Handler, returning its Address if it exists.
        /// Note, removing a Handler does not revoke key access linked account if it has been added. This should be
        /// done in the same transaction in which this method is called.
        ///
        /// @param withAddress: The Address of the linked account to remove from the mapping
        ///
        /// @return the Address of the account removed or nil if it wasn't linked to begin with
        ///
        pub fun removeLinkedAccount(withAddress: Address): [Type] {
            pre {
                self.addressToID.containsKey(withAddress):
                    "This Collection does not have NFT with given Address: ".concat(withAddress.toString())
            }
            // Withdraw the NFT
            let nft: @LinkedAccounts.NFT <-self.withdrawByAddress(address: withAddress) as! @NFT
            let nftID: UInt64 = nft.id
            
            // Get a reference to the Handler from the NFT
            let handlerRef: &LinkedAccounts.Handler = nft.getHandlerRef()
            // Set the handler as inactive
            handlerRef.setInactive()
            // Remove all capabilities from the Handler
            let removedCapTypes: [Type] = handlerRef.revokeAllCapabilities()

            // Emit RemovedLinkedAccount & destroy NFT
            emit RemovedLinkedAccount(parent: self.owner!.address, child: withAddress)
            destroy nft
            return removedCapTypes
        }

        destroy () {
            pre {
                // Prevent destruction while account delegations remain in NFTs
                self.ownedNFTs.length == 0:
                    "Attempting to destroy Colleciton with remaining NFTs!"
            }
            destroy self.ownedNFTs
        }
        
    }

    /// Helper method to determine if a public key is active on an account by comparing the given key against all keys
    /// active on the given account.
    ///
    /// @param publicKey: A public key as a string
    /// @param address: The address of the 
    ///
    /// @return True if the key is active on the account, false otherwise (including if the given public key string was
    /// invalid)
    ///
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
        }
        return false
    }

    /// Returns a new Collection
    ///
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        emit CollectionCreated()
        return <-create Collection()
    }

    /// Function that returns all the Metadata Views implemented by a Non Fungible Token
    ///
    /// @return An array of Types defining the implemented views. This value will be used by
    ///         developers to know which parameter to pass to the resolveView() method.
    ///
    pub fun getViews(): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>()
        ]
    }

    /// Function that resolves a metadata view for this contract.
    ///
    /// @param view: The Type of the desired view.
    /// @return A structure representing the requested view.
    ///
    pub fun resolveView(_ view: Type): AnyStruct? {
        switch view {
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                    storagePath: LinkedAccounts.CollectionStoragePath,
                    publicPath: LinkedAccounts.CollectionPublicPath,
                    providerPath: LinkedAccounts.CollectionPrivatePath,
                    publicCollection: Type<&LinkedAccounts.Collection{LinkedAccounts.CollectionPublic}>(),
                    publicLinkedType: Type<&LinkedAccounts.Collection{LinkedAccounts.CollectionPublic, MetadataViews.ResolverCollection}>(),
                    providerLinkedType: Type<&LinkedAccounts.Collection{LinkedAccounts.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(),
                    createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                        return <-LinkedAccounts.createEmptyCollection()
                    })
                )
            case Type<MetadataViews.NFTCollectionDisplay>():
                let media = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"
                    ),
                    mediaType: "image/svg+xml"
                )
        }
        return nil
    }

    /// Contract mint method enabling caller to mint an NFT, wrapping the provided Capabilities
    ///
    /// @param authAccountCap: The AuthAccount Capability that will be wrapped in the minted NFT
    /// @param handlerCap: The Handler Capability that will be wrapped in the minted NFT
    ///
    /// @return the newly created NFT
    ///
    access(contract) fun mintNFT(
        authAccountCap: Capability<&AuthAccount>,
        handlerCap: Capability<&Handler>
    ): @NFT {
        return <-create NFT(
            authAccountCap: authAccountCap,
            handlerCap: handlerCap
        )
    }

    init() {

        self.totalSupply = 0

        // Assign Collection paths
        self.CollectionStoragePath = /storage/LinkedAccountCollection
        self.CollectionPublicPath = /public/LinkedAccountCollection
        self.CollectionPrivatePath = /private/LinkedAccountCollection
        // Assign Handler paths
        self.HandlerStoragePath = /storage/LinkedAccountHandler
        self.HandlerPublicPath = /public/LinkedAccountHandler
        self.HandlerPrivatePath = /private/LinkedAccountHandler

        emit ContractInitialized()
    }
}
 