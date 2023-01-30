import NonFungibleToken from "./utility/NonFungibleToken.cdc"
import MetadataViews from "./utility/MetadataViews.cdc"

pub contract MonsterMaker: NonFungibleToken {

    // totalSupply
    // The total number of MonsterMaker that have been minted
    //
    pub var totalSupply: UInt64

    // Events
    //
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64, component: MonsterComponent)

    // Named Paths
    //
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let ProviderPrivatePath: PrivatePath
    pub let MinterStoragePath: StoragePath
    pub let MinterPrivatePath: PrivatePath

    pub struct MonsterComponent {
        pub var background: Int
        pub var head: Int
        pub var torso: Int
        pub var legs: Int

        init(background: Int, head: Int, torso: Int, legs: Int) {
            self.background = background
            self.head = head
            self.torso = torso
            self.legs = legs
        }
    }

    pub fun componentToString(_ component: MonsterComponent): String {
        return component.background.toString()
        .concat("-")
        .concat(component.head.toString())
        .concat("-")
        .concat(component.torso.toString())
        .concat("-")
        .concat(component.legs.toString())
    }
    
    // A Monster Item as an NFT
    //
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64

        pub fun name(): String {
            return "Monster"
                .concat(" #")
                .concat(self.id.toString())
        }
        
        pub fun description(): String {
            return "Monster "
                .concat(" with serial number ")
                .concat(self.id.toString())
        }


        pub fun thumbnail(): MetadataViews.HTTPFile {
          return MetadataViews.HTTPFile(url: "https://monster-maker.vercel.app/api/image/".concat(MonsterMaker.componentToString(self.component)))
        }

        access(self) let royalties: [MetadataViews.Royalty]
        access(self) let metadata: {String: AnyStruct}


        pub let component: MonsterMaker.MonsterComponent

        init(
            royalties: [MetadataViews.Royalty],
            metadata: {String: AnyStruct},
            component: MonsterMaker.MonsterComponent,    
        ){
            self.id = self.uuid
            self.royalties = royalties
            self.metadata = metadata
            self.component = component
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>(),
                Type<MetadataViews.Royalties>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name(),
                        description: self.description(),
                        thumbnail: self.thumbnail()
                    )
                case Type<MetadataViews.Editions>():
                    // There is no max number of NFTs that can be minted from this contract
                    // so the max edition field value is set to nil
                    let editionInfo = MetadataViews.Edition(name: "MonsterMaker NFT Edition", number: self.id, max: nil)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(
                        editionList
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
                    return MetadataViews.ExternalURL("https://monster-maker.vercel.app/".concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: MonsterMaker.CollectionStoragePath,
                        publicPath: MonsterMaker.CollectionPublicPath,
                        providerPath: /private/MonsterMakerCollection,
                        publicCollection: Type<&MonsterMaker.Collection{MonsterMaker.MonsterMakerCollectionPublic}>(),
                        publicLinkedType: Type<&MonsterMaker.Collection{MonsterMaker.MonsterMakerCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&MonsterMaker.Collection{MonsterMaker.MonsterMakerCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-MonsterMaker.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://i.imgur.com/UMXsEjt.png"
                        ),
                        mediaType: "image/png"
                    )

                    let bannerMedia = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://i.imgur.com/NzV9cyo.png"
                        ),
                        mediaType: "image/png"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "The MonsterMaker Collection",
                        description: "This collection is used as an example to help you develop your next Flow NFT.",
                        externalURL: MetadataViews.ExternalURL("https://monster-maker.vercel.app/"),
                        squareImage: media,
                        bannerImage: bannerMedia,
                        socials: {}
                    )
                case Type<MetadataViews.Traits>():
                    // exclude mintedTime and foo to show other uses of Traits
                    let excludedTraits = ["mintedTime", "foo"]
                    let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)

                    return traitsView
            }
            return nil 
        }
    }

    // This is the interface that users can cast their MonsterMaker Collection as
    // to allow others to deposit MonsterMaker into their Collection. It also allows for reading
    // the details of MonsterMaker in the Collection.
    pub resource interface MonsterMakerCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowMonsterMaker(id: UInt64): &MonsterMaker.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow MonsterMaker reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection
    // A collection of MonsterMaker NFTs owned by an account
    //
    pub resource Collection: MonsterMakerCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        //
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // initializer
        //
        init () {
            self.ownedNFTs <- {}
        }

        // withdraw 
        // removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit 
        // takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @MonsterMaker.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs 
        // returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT 
        // gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        // borrowMonsterMaker
        // Gets a reference to an NFT in the collection as a MonsterMaker,
        // exposing all of its fields (including the typeID & rarityID).
        // This is safe as there are no functions that can be called on the MonsterMaker.
        //
        pub fun borrowMonsterMaker(id: UInt64): &MonsterMaker.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &MonsterMaker.NFT
            } else {
                return nil
            }    
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let MonsterMaker = nft as! &MonsterMaker.NFT
            return MonsterMaker as &AnyResource{MetadataViews.Resolver}
        }

        // destructor
        destroy() {
            destroy self.ownedNFTs
        }
    }

    // createEmptyCollection
    // public function that anyone can call to create a new empty collection
    //
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // NFTMinter
    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
    pub resource NFTMinter {

        // mintNFT
        // Mints a new NFT with a new ID
        // and deposit it in the recipients collection using their collection reference
        //
        pub fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic}, 
            component: MonsterMaker.MonsterComponent,
            royalties: [MetadataViews.Royalty],
        ) {
            let metadata: {String: AnyStruct} = {}
            let currentBlock = getCurrentBlock()
            metadata["mintedBlock"] = currentBlock.height
            metadata["mintedTime"] = currentBlock.timestamp
            metadata["minter"] = recipient.owner!.address
            metadata["background"] = component.background
            metadata["head"] = component.head
            metadata["torso"] = component.torso
            metadata["legs"] = component.legs

            // this piece of metadata will be used to show embedding rarity into a trait
            // metadata["foo"] = "bar"

            // create a new NFT
            var newNFT <- create MonsterMaker.NFT(
                royalties: royalties,
                metadata: metadata,
                component: component, 
            )

            let mintedID = newNFT.id

            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newNFT)

            emit Minted(
                id: mintedID,
                component: component,
            )

            MonsterMaker.totalSupply = MonsterMaker.totalSupply + UInt64(1)
        }
    }

    // fetch
    // Get a reference to a MonsterMaker from an account's Collection, if available.
    // If an account does not have a MonsterMaker.Collection, panic.
    // If it has a collection but does not contain the itemID, return nil.
    // If it has a collection and that collection contains the itemID, return a reference to that.
    //
    pub fun fetch(_ from: Address, itemID: UInt64): &MonsterMaker.NFT? {
        let collection = getAccount(from)
            .getCapability(MonsterMaker.CollectionPublicPath)!
            .borrow<&MonsterMaker.Collection{MonsterMaker.MonsterMakerCollectionPublic}>()
            ?? panic("Couldn't get collection")
        // We trust MonsterMaker.Collection.borowMonsterMaker to get the correct itemID
        // (it checks it before returning it).
        return collection.borrowMonsterMaker(id: itemID)
    }

    // initializer
    //
    init() {

        // Initialize the total supply
        self.totalSupply = 0

        // Set our named paths
        self.CollectionStoragePath = /storage/MonsterMakerCollection
        self.CollectionPublicPath = /public/MonsterMakerCollection
        self.ProviderPrivatePath = /private/MonsterMakerCollectionProvider
        self.MinterStoragePath = /storage/MonsterMakerMinter
        self.MinterPrivatePath = /private/MonsterMakerMinter

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // Create a public capability for the collection
        self.account.link<&MonsterMaker.Collection{NonFungibleToken.CollectionPublic, MonsterMaker.MonsterMakerCollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}
