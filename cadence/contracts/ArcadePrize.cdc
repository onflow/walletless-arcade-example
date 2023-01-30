import NonFungibleToken from "./utility/NonFungibleToken.cdc"
import FungibleToken from "./utility/FungibleToken.cdc"
import MetadataViews from "./utility/MetadataViews.cdc"
import TicketToken from "./TicketToken.cdc"

pub contract ArcadePrize: NonFungibleToken {

    /// Total supply of ArcadePrizes in existence
    pub var totalSupply: UInt64

    /// The event that is emitted when the contract is created
    pub event ContractInitialized()

    /// The event that is emitted when an NFT is withdrawn from a Collection
    pub event Withdraw(id: UInt64, from: Address?)

    /// The event that is emitted when an NFT is deposited to a Collection
    pub event Deposit(id: UInt64, to: Address?)

    /// Storage and Public Paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let ProviderPrivatePath: PrivatePath
    pub let AdminStoragePath: StoragePath
    pub let MinterPublicPath: PublicPath
    pub let AdminPrivatePath: PrivatePath
    pub let VaultStoragePath: StoragePath

    /// Mapping of prize type to price
    pub let prizePrices: {PrizeType: UFix64}
    /// Mapping of prize type to its corresponding metadata
    pub let prizeTypeMetadata: {PrizeType: {String: AnyStruct}}

    /// An enum indicating the type of prize an NFT represents
    pub enum PrizeType: Int {
        pub case RAINBOWDUCK
    }

    /// The core resource that represents a Non Fungible Token. 
    /// New instances will be created using the NFTMinter resource
    /// and stored in the Collection resource
    ///
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        
        /// The unique ID that each NFT has
        pub let id: UInt64
        /// The type of the prize
        pub let prizeType: PrizeType

        /// Metadata fields
        pub let name: String
        pub let description: String
        pub let thumbnail: String
        access(self) let royalties: [MetadataViews.Royalty]
        access(self) let metadata: {String: AnyStruct}
    
        init(
            metadata: {String: AnyStruct}
        ) {
            self.id = self.uuid
            self.name = (metadata["name"] as! String?)!
            self.description = (metadata["description"] as! String?)!
            self.thumbnail = (metadata["thumbnail"] as! String?)!
            let genericRoyalties = metadata["royalties"] as! [AnyStruct]?
            self.royalties = ArcadePrize.castArrayToRoyalties(genericArray: genericRoyalties)
            self.metadata = metadata
            self.prizeType = (metadata["prizeType"] as! PrizeType?)!
        }

        /// Function that returns all the Metadata Views implemented by a Non Fungible Token
        ///
        /// @return An array of Types defining the implemented views. This value will be used by
        ///         developers to know which parameter to pass to the resolveView() method.
        ///
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>()
            ]
        }

        /// Function that resolves a metadata view for this token.
        ///
        /// @param view: The Type of the desired view.
        /// @return A structure representing the requested view.
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
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        self.royalties
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://arcade.onflow.org/".concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: ArcadePrize.CollectionStoragePath,
                        publicPath: ArcadePrize.CollectionPublicPath,
                        providerPath: /private/ArcadePrizeCollection,
                        publicCollection: Type<&ArcadePrize.Collection{ArcadePrize.ArcadePrizeCollectionPublic}>(),
                        publicLinkedType: Type<&ArcadePrize.Collection{ArcadePrize.ArcadePrizeCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&ArcadePrize.Collection{ArcadePrize.ArcadePrizeCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-ArcadePrize.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://cdn.midjourney.com/06e2a096-3b27-4310-ac79-929e0fe63aa7/grid_0.png"
                        ),
                        mediaType: "image/png"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "The ArcadePrize Collection",
                        description: "A collection of arcade prizes for on-chain arcade games!",
                        externalURL: MetadataViews.ExternalURL("https://arcade.onflow.org"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/flow_blockchain")
                        }
                    )
            }
            return nil
        }
    }

    /// Defines the methods that are particular to this NFT contract collection
    ///
    pub resource interface ArcadePrizeCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowArcadePrize(id: UInt64): &ArcadePrize.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow ArcadePrize reference: the ID of the returned reference is incorrect"
            }
        }
    }

    /// The resource that will be holding the NFTs inside any account.
    /// In order to be able to manage NFTs any account will need to create
    /// an empty collection first
    ///
    pub resource Collection: ArcadePrizeCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        /// Removes an NFT from the collection and moves it to the caller
        ///
        /// @param withdrawID: The ID of the NFT that wants to be withdrawn
        /// @return The NFT resource that has been taken out of the collection
        ///
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        /// Adds an NFT to the collections dictionary and adds the ID to the id array
        ///
        /// @param token: The NFT resource to be included in the collection
        /// 
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @ArcadePrize.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        /// Helper method for getting the collection IDs
        ///
        /// @return An array containing the IDs of the NFTs in the collection
        ///
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        /// Gets a reference to an NFT in the collection so that 
        /// the caller can read its metadata and call its methods
        ///
        /// @param id: The ID of the wanted NFT
        /// @return A reference to the wanted NFT resource
        ///
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }
 
        /// Gets a reference to an NFT in the collection so that 
        /// the caller can read its metadata and call its methods
        ///
        /// @param id: The ID of the wanted NFT
        /// @return A reference to the wanted NFT resource
        ///        
        pub fun borrowArcadePrize(id: UInt64): &ArcadePrize.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &ArcadePrize.NFT
            }

            return nil
        }

        /// Gets a reference to the NFT only conforming to the `{MetadataViews.Resolver}`
        /// interface so that the caller can retrieve the views that the NFT
        /// is implementing and resolve them
        ///
        /// @param id: The ID of the wanted NFT
        /// @return The resource reference conforming to the Resolver interface
        /// 
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let arcadePrizeNFT = nft as! &ArcadePrize.NFT
            return arcadePrizeNFT as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    /* Admin interfaces & resource */

    pub resource interface NFTMinterPublic {
        pub fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            prizeType: PrizeType,
            payment: @FungibleToken.Vault
        )
    }

    pub resource interface NFTAdmin {
        pub fun updatePrice(prizeType: PrizeType, price: UFix64)
        pub fun updateMetada(prizeType: PrizeType, metadata: {String: AnyStruct})
    }

    /// Resource that an admin or something similar would own to be
    /// able to mint new NFTs
    ///
    pub resource Administrator : NFTMinterPublic, NFTAdmin, FungibleToken.Receiver, FungibleToken.Provider {

        /* NFTMinterPublic */

        /// Mints a new NFT with a new ID and deposit it in the
        /// recipients collection using their collection reference
        ///
        /// @param recipient: A capability to the collection where the new NFT will be deposited
        /// @param prizeType: The type of prize the caller wants to mint
        /// @param payment: A vault containing the payment for mint
        ///     
        pub fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            prizeType: PrizeType,
            payment: @FungibleToken.Vault
        ) {
            pre {
                ArcadePrize.prizePrices.containsKey(prizeType) && ArcadePrize.prizeTypeMetadata.containsKey(prizeType):
                    "Desired prize type is not valid!"
                ArcadePrize.prizePrices[prizeType] == payment.balance:
                    "Incorrect payment amount for desired prize!"
            }
            let metadata: {String: AnyStruct} = ArcadePrize.prizeTypeMetadata[prizeType]!
            let currentBlock = getCurrentBlock()
            metadata["mintedBlock"] = currentBlock.height
            metadata["mintedTime"] = currentBlock.timestamp
            metadata["minter"] = recipient.owner!.address

            // this piece of metadata will be used to show embedding rarity into a trait
            metadata["prizeType"] = prizeType

            // create a new NFT
            var newNFT <- create NFT(
                metadata: metadata
            )

            // deposit payment to the contract's Vault
            self.deposit(from: <-payment)

            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newNFT)

            ArcadePrize.totalSupply = ArcadePrize.totalSupply + UInt64(1)
        }

        /* NFTAdmin */
        
        /// Method to update price of a prize type
        pub fun updatePrice(prizeType: PrizeType, price: UFix64) {
            ArcadePrize.prizePrices[prizeType] = price
        }

        /// Method to update metadata associated with a prize type
        pub fun updateMetada(prizeType: PrizeType, metadata: {String: AnyStruct}) {
            ArcadePrize.prizeTypeMetadata[prizeType] = metadata
        }

        /* Receiver */
        //
        pub fun deposit(from: @FungibleToken.Vault) {
            ArcadePrize.borrowVaultRef().deposit(from: <-from)
        }
        /* Provider */
        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            return <-ArcadePrize.borrowVaultRef().withdraw(amount: amount)
        }
    }

    /// Allows anyone to create a new empty collection
    ///
    /// @return The new Collection resource
    ///
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    /// Getter method to resolve metadata for the specified prize type as Display struct
    /// or nil if the given prizeType doesn't exist
    ///
    /// @param prizeType: The type of prize (as declared in the enum PrizeType) for which
    /// to resolve metadata
    ///
    /// @return The type's metadata as defined in the contract mapping prizeTypeMetadata
    /// as a MetadataViews.Display struct or nil if the prizeType is invalid
    ///
    pub fun getPrizeTypeDisplayView(prizeType: PrizeType): MetadataViews.Display? {
        if let metadata = self.prizeTypeMetadata[prizeType] {
            return MetadataViews.Display(
                name: (metadata["name"] as! String?)!,
                description: (metadata["description"] as! String?)!,
                thumbnail: MetadataViews.HTTPFile(
                    url: (metadata["thumbnail"] as! String?)!
                )
            )
        }
        return nil
    }

    /// Contract helper function to cast [AnyStruct] to [MetadataViews.Royalty]
    pub fun castArrayToRoyalties(genericArray: [AnyStruct]?): [MetadataViews.Royalty] {
        if genericArray == nil {
            return []
        }
        let returnArr: [MetadataViews.Royalty] = []
        for element in genericArray! {
            returnArr.append(element as! MetadataViews.Royalty)
        }
        return returnArr
    }

    /// Contract helper method, returning a reference to the contract's Vault
    access(contract) fun borrowVaultRef(): &FungibleToken.Vault {
        // let fromVault <- from as! @TicketTokens.Vault
        let vaultRef = self.account
            .borrow<
                &FungibleToken.Vault
            >(
                from: self.VaultStoragePath
            ) ?? panic("Could not borrow reference to contract's Vault!")
        return vaultRef
    }

    init() {
        // Initialize the total supply
        self.totalSupply = 0

        // Set the named paths
        self.CollectionStoragePath = /storage/ArcadePrizeCollection
        self.CollectionPublicPath = /public/ArcadePrizeCollection
        self.ProviderPrivatePath = /private/ArcadePrizeCollectionProvider
        self.AdminStoragePath = /storage/ArcadePrizeAdmin
        self.MinterPublicPath = /public/ArcadePrizeMinter
        self.AdminPrivatePath = /private/ArcadePrizeAdmin
        self.VaultStoragePath = /storage/ArcadePrizeVault

        // Set the contract variables
        self.prizePrices = {PrizeType.RAINBOWDUCK: 10.0}
        self.prizeTypeMetadata = {
                PrizeType.RAINBOWDUCK: {
                    "prizeType": PrizeType.RAINBOWDUCK,
                    "name": "Rainbow Duck",
                    "description": "The happiest rainbow duck friend, prized for its vibrant feathers!",
                    "royalties": [],
                    "thumbnail": "https://cdn.discordapp.com/attachments/1008571155977863199/1067574936866127892/JeffD_a_realistic_bright_furry_happy_smiling_rainbow_rubber_duc_37823616-b20f-4b28-a97a-0803237252cf.png"
                }
            }

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // create a public capability for the collection
        self.account.link<&ArcadePrize.Collection{NonFungibleToken.CollectionPublic, ArcadePrize.ArcadePrizeCollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        // Create a Minter resource and save it to storage
        let minter <- create Administrator()
        self.account.save(<-minter, to: self.AdminStoragePath)
        self.account.link<&Administrator{NFTMinterPublic}>(self.MinterPublicPath, target: self.AdminStoragePath)
        self.account.link<
            &Administrator{NFTAdmin, FungibleToken.Provider, FungibleToken.Receiver}
        >(
            self.AdminPrivatePath,
            target: self.AdminStoragePath
        )

        // Create a Vault & save to contract
        self.account.save(<-TicketToken.createEmptyVault(), to: self.VaultStoragePath)

        emit ContractInitialized()
    }
}
 