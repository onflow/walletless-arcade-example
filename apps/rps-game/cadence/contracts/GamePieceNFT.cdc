import FungibleToken from "./utility/FungibleToken.cdc"
import NonFungibleToken from "./utility/NonFungibleToken.cdc"
import MetadataViews from "./utility/MetadataViews.cdc"
import GamingMetadataViews from "./GamingMetadataViews.cdc"

/// GamePieceNFT
///
/// In this contract, we defined a generic NFT meant to be used as a
/// base resource for game-related attachments. In this suite of contracts,
/// RPSWinLossRetriever and RPSAssignedMoves are attached, enabling RPS
/// related functionality in the base resource.
///
/// Once attachment iteration is enabled, this contract can be updated to
/// support game attachment related methods within the NFT. For now, it remains
/// a simple NFT implementation to demonstrate Cadence's native attachments. The
/// use of attachments on an NFT for the purpose of gaming allows for attributes
/// related to the NFT to be altered under the typical Capabilities-based
/// access controls Cadence enables while maintaining an open, composable
/// system of building blocks the whole ecosystem can leverage to build awesome
/// games.
///
/// We hope that this pattern can be built on for more complex gaming
/// applications with more complex metadata as a powerful method for 
/// defining attributes that can be mutated, but in a manner that ensures
/// mutation is only performed by the game in which the NFT is played.
///
pub contract GamePieceNFT: NonFungibleToken {

    /// Counter to track total circulating supply
    pub var totalSupply: UInt64

    /* Collection related paths */
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let ProviderPrivatePath: PrivatePath
    
    /* Minter related paths */
    pub let MinterStoragePath: StoragePath
    pub let MinterPublicPath: PublicPath
    pub let MinterPrivatePath: PrivatePath
    
    pub event ContractInitialized()
    /* NFT related events */
    pub event MintedNFT(id: UInt64, totalSupply: UInt64)
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    /// The definition of the GamePieceNFT.NFT resource, an NFT designed to be used for gameplay with
    /// attributes relevant to win/loss histories and basic gameplay moves
    ///
    pub resource NFT : NonFungibleToken.INFT, MetadataViews.Resolver {
        /// Unique id tied to resource's UUID
        pub let id: UInt64

        /// Metadata fields
        pub let name: String
        pub let description: String
        pub let thumbnail: String

        init(
            metadata: {String: AnyStruct}
        ) {
            self.id = self.uuid
            self.name = metadata["name"]! as! String
            self.description = metadata["description"]! as! String
            self.thumbnail = metadata["thumbnail"]! as! String
        }

        /** --- MetadataViews.Resolver --- */
        /// Retrieve relevant MetadataViews and/or GamingMetadataViews struct types supported by this
        /// NFT
        ///
        /// @return array of view Types relevant to this NFT
        ///
        pub fun getViews(): [Type] {
            let views: [Type] = [
                    Type<MetadataViews.Display>(),
                    Type<MetadataViews.Serial>(),
                    Type<MetadataViews.ExternalURL>(),
                    Type<MetadataViews.NFTCollectionData>()
                ]
            return views
        }
        
        /// Function that resolve the given GameMetadataView
        ///
        /// @param view: The Type of GameMetadataView to resolve
        ///
        /// @return The resolved GameMetadataView for this NFT with this NFT's
        /// metadata or nil if none exists
        ///
        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.thumbnail
                        )
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://gamepiece-nft.onflow.org/".concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: GamePieceNFT.CollectionStoragePath,
                        publicPath: GamePieceNFT.CollectionPublicPath,
                        providerPath: GamePieceNFT.ProviderPrivatePath,
                        publicCollection: Type<&GamePieceNFT.Collection{GamePieceNFT.GamePieceNFTCollectionPublic}>(),
                        publicLinkedType: Type<&GamePieceNFT.Collection{GamePieceNFT.GamePieceNFTCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&GamePieceNFT.Collection{GamePieceNFT.GamePieceNFTCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-GamePieceNFT.createEmptyCollection()
                        })
                    )
                default:
                    return nil
            }
        }
    }

    /** --- Collection Interface & resource --- */

    /// An interface defining the public methods for a GamePieceNFT Collection
    pub resource interface GamePieceNFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowNFTSafe(id: UInt64): &NonFungibleToken.NFT? {
            post {
                result == nil || result!.id == id: "The returned reference's ID does not match the requested ID"
            }
        }
        pub fun borrowGamePieceNFT(
            id: UInt64
        ): &GamePieceNFT.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow GamePieceNFT reference: the ID of the returned reference is incorrect"
            }
            return nil
        }
        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver}
    }

    pub resource Collection : GamePieceNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        /// Dictionary of NFT conforming tokens
        /// NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        /// Removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        /// Takes a NonFungibleToken.NFT and adds it to the collections dictionary
        /// indexed on the tokens id
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @GamePieceNFT.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        /// Returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        /// Gets a reference to an NFT in the collection as NonFungibleToken.NFT
        /// so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        /// Safe way to borrow a reference to an NFT that does not panic
        ///
        /// @param id: The ID of the NFT that want to be borrowed
        /// @return An optional reference to the desired NFT, will be nil if the passed id does not exist
        ///
        pub fun borrowNFTSafe(id: UInt64): &NonFungibleToken.NFT? {
            if let nftRef = &self.ownedNFTs[id] as &NonFungibleToken.NFT? {
                return nftRef
            }
            return nil
        }
 
        /// Returns a reference to the GamePieceNFT.NFT as a restricted composite Type
        ///
        /// @param id: The id of the NFT for which a reference will be returned 
        ///
        /// @return The reference to the NFT or nil if it is not contained in the Collection
        ///
        pub fun borrowGamePieceNFT(
            id: UInt64
        ): &GamePieceNFT.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &GamePieceNFT.NFT
            }
            return nil
        }

        /// Returns a reference to the nft with given id as a MetadataViews.Resolver
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            pre {
                self.ownedNFTs.containsKey(id):
                    "Collection does not contain Resolver with id ".concat(id.toString())
            }
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let gamePieceNFT = nft as! &GamePieceNFT.NFT
            return gamePieceNFT
        }

        destroy() {
            pre {
                self.ownedNFTs.length == 0:
                    "NFTs still contained in this Collection!"
            }
            destroy self.ownedNFTs
        }
    }

    /// Public function that anyone can call to create a new empty collection
    ///
    /// @return a new empty Collection resource
    ///
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        let newCollection <- create Collection() as! @NonFungibleToken.Collection
        return <- newCollection
    }


    /* --- Minter --- */

    /// Admin interface enabling Metadata updates, setting minting permissions
    /// and minting NFT
    ///
    pub resource interface MinterAdmin {
        pub fun setMetadata(metadata: {String: AnyStruct})
        pub fun setMintingPermissions(allowMinting: Bool)
        pub fun isMintingAllowed(): Bool
        pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic})
    }

    /// Public facing interface enabling for public minting of an NFT
    ///
    pub resource interface MinterPublic {
        pub fun isMintingAllowed(): Bool
        pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic})
    }

    /// Resource allowing for minting of GamePieceNFT.NFT with helper methods for
    /// an admin to set metadata, allow/disallow minting
    ///
    pub resource Minter : MinterAdmin, MinterPublic {
        /// Boolean defining whether minting is/is not allowed
        access(self) var allowMinting: Bool
        /// Metadata mapping value name to AnyStruct, enabling for metadata updates
        /// since the generic GamePieceNFT maintains consistent metadata across each
        /// resource as a base for game-related attachments
        access(self) var metadata: {String: AnyStruct}
        
        init() {
            self.allowMinting = true
            self.metadata = {
                "name": "GamePieceNFT",
                "description": "One game piece NFT to rule them all!",
                "thumbnail": "https://www.cheezewizards.com/static/img/prizePool/coin.svg"
            }
        }

        /* --- MinterAdmin --- */

        /// Allows MinterAdmin to set new metadata values which are passed to NFTs on init
        ///
        /// @param metadata: Mapping of string to AnyStruct defining the metadata structure
        /// to be passed on NFTs on creation
        /// 
        pub fun setMetadata(metadata: {String: AnyStruct}) {
            self.metadata = metadata
        }

        /// Allows MinterAdmin to allow/disallow minting
        ///
        /// @param allowMinting: true/false value defining whether minting is allowed
        ///
        pub fun setMintingPermissions(allowMinting: Bool) {
            self.allowMinting = allowMinting
        }

        /* --- MinterPublic & MinterAdmin --- */
        /// Basic method to determine if minting is currently enabled
        ///
        /// @return true/false value
        ///
        pub fun isMintingAllowed(): Bool {
            return self.allowMinting
        }

        /// Allows for minting of NFTs. For the purposes of this proof of concept,
        /// this is set to free. Rudimentary spam minimization is done by
        /// GamePieceNFT.allowMinting, but one might consider requiring payment
        /// to mint an NFT
        ///
        /// @param recipient: A reference to the requestor's CollectionPublic
        /// to which the NFT will be deposited
        ///
        pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}) {
            pre {
                self.allowMinting: "Minting is not currently enabled!"
            }
            // Increment the supply
            GamePieceNFT.totalSupply = GamePieceNFT.totalSupply + UInt64(1)
            
            // Create a new NFT. A typical NFT's Metadata would vary, but for simplicity and because the attachments
            // are really what characterize each NFT, we've standardized each NFT in this contract
            let newNFT <- create NFT(
                    metadata: self.metadata
                ) as @NonFungibleToken.NFT

            // Get the id & deposit the token to the Receiver
            let newID: UInt64 = newNFT.id
            recipient.deposit(token: <-newNFT)

            emit MintedNFT(id: newID, totalSupply: GamePieceNFT.totalSupply)
        }
    }

    init() {
        
        self.totalSupply = 0

        // Set Collection paths
        self.CollectionStoragePath = /storage/GamePieceNFTCollection
        self.CollectionPublicPath = /public/GamePieceNFTCollection
        self.ProviderPrivatePath = /private/GamePieceNFTCollectionProvider
        // Set Minter paths
        self.MinterStoragePath = /storage/GamePieceNFTMinter
        self.MinterPublicPath = /public/GamePieceNFTMinter
        self.MinterPrivatePath = /private/GamePieceNFTMinter

        // Create & save the Minter resource
        self.account.save(<-create Minter(), to: self.MinterStoragePath)
        // Link the minter as a Public Capability
        self.account.link<&{MinterPublic}>(self.MinterPublicPath, target: self.MinterStoragePath)
        self.account.link<&{MinterAdmin}>(self.MinterPrivatePath, target: self.MinterStoragePath)

        emit ContractInitialized()
    }
}
 