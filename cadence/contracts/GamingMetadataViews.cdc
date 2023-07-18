import "MetadataViews"

/// GamingMetadataViews
///
/// This contract is an initial implementation of gaming related
/// win/loss metadata and mechanisms to retrieve win/loss records
/// from games in which the NFT was played.
/// 
pub contract GamingMetadataViews {

    /// A struct defining metadata relevant to a game contract
    ///
    pub struct GameContractMetadata {
        pub let name: String
        pub let description: String
        pub let icon: AnyStruct{MetadataViews.File}
        pub let thumbnail: AnyStruct{MetadataViews.File}
        pub let contractAddress: Address
        pub let externalURL: MetadataViews.ExternalURL
        
        init(
            name: String,
            description: String,
            icon: AnyStruct{MetadataViews.File},
            thumbnail: AnyStruct{MetadataViews.File},
            contractAddress: Address,
            externalURL: MetadataViews.ExternalURL
        ) {
            self.name = name
            self.description = description
            self.icon = icon
            self.thumbnail = thumbnail
            self.contractAddress = contractAddress
            self.externalURL = externalURL
        }
    }

    /// Struct that contains attributes and methods relevant to win/loss/tie
    /// record and mechanisms to increment such values
    ///
    pub struct BasicWinLoss {
        /// The name of the associated game
        pub let gameName: String
        /// The id of the associated NFT (nft.uuid based on updated NFTv2 standard)
        pub let nftID: UInt64

        /// Aggregate game results
        access(self) var wins: UInt64
        access(self) var losses: UInt64
        access(self) var ties: UInt64

        init (game: String, nftID: UInt64){
            self.gameName = game
            self.nftID = nftID
            self.wins = 0
            self.losses = 0
            self.ties = 0
        }

        /** --- Value Incrementers --- */
        ///
        /// Below are methods to increment and decrement win/loss/ties
        /// aggregate values.

        pub fun addWin () {
            self.wins = self.wins + 1
        }
        pub fun addLoss () {
            self.losses = self.losses + 1
        }
        pub fun addTie () {
            self.ties = self.ties + 1
        }
        
        pub fun subtractWin() {
            if self.wins > 0 {
                self.wins = self.wins - 1
            }
        }
        pub fun subtractLoss() {
            if self.losses > 0 {
                self.losses = self.losses - 1
            }
        }
        pub fun subtractTie() {
            if self.ties > 0 {
                self.ties = self.ties - 1
            }
        }

        /// Resets the records to 0
        pub fun reset() {
            self.wins = 0
            self.losses = 0
            self.ties = 0
        }
    }

    /// View struct conatining info relating to the associated game, nft & assigned moves.
    /// Designed to be returned by a resource implementing MetadataViews.Resolver and
    /// AssignedMoves (see below)
    ///
    pub struct AssignedMovesView {
        /// The name of the associated game
        pub let gameName: String
        /// The id of the associated NFT (nft.uuid based on updated NFTv2 standard)
        pub let nftID: UInt64
        /// Array designed to contain an array of generic moves
        pub let moves: [AnyStruct]

        init(gameName: String, nftID: UInt64, moves: [AnyStruct]) {
            self.gameName = gameName
            self.nftID = nftID
            self.moves = moves
        }
    }

    /// View struct containing the nftID & a mapping of indexed on the NFT's GameResource attachment
    /// types and their associated GameContractMetadata
    ///
    /// NOTE: Can't resolve this within an NFT without attachment iteration
    ///
    pub struct GameAttachmentsView {
        /// The id of the associated NFT (nft.uuid based on updated NFTv2 standard)
        pub let nftID: UInt64
        /// Mapping of the Types to their associated GameContractMetadata 
        pub let attachmentGameContractMetadata: {Type: GameContractMetadata}

        init(nftID: UInt64, attachmentGameContractMetadata: {Type: GameContractMetadata}) {
            self.nftID = nftID
            self.attachmentGameContractMetadata = attachmentGameContractMetadata
        }
    }

    /** --- Interfaces --- */
    
    /// Basic interface containing Metadata about a game-related attachment
    ///
    pub resource interface GameResource {
        pub let gameContractInfo: GameContractMetadata
    }

    /// Interface which returns BasicWinLoss data an NFT. Designed
    /// to be implemented in conjunction with GameResource as
    /// an attachment to an NFT.
    ///
    pub resource interface BasicWinLossRetriever {
        /// The ID of the NFT to which this resource is attached
        pub let nftID: UInt64
        /// Struct containing info about the related game contract
        pub let gameContractInfo: GameContractMetadata

        /// Retrieves the BasicWinLoss for the NFT associated with nftID
        /// (nft.uuid based on updated NFTv2 standard)
        ///
        /// @return the BasicWinLoss record for the NFT to which the retriever is attached
        ///
        pub fun getWinLossData(): BasicWinLoss?

        /// Allows the owner to reset the WinLoss records of the base NFT
        //  TODO: Implement once we can define access for attachments via reference to base vs. base resource
        //  - IOW: r[RPSWinLossRetriever].resetWinLossData() should fail when r: &R and succeed when r: @R
        // pub fun resetWinLossData()
    }

    /// A resource interface defining an attachment representative of a simple
    /// win/loss record. Whereas BasicWinLossRetriever is designed to retrieve
    /// a BasicWinLoss struct stored centrally in a contract, an attachment
    /// implementing this interface can store the win/loss data locally.
    ///
    pub resource interface WinLoss {
        /// Struct containing info about the related game contract
        pub let gameContractInfo: GameContractMetadata

        /** --- Game record variables --- */
        access(contract) var wins: UInt64
        access(contract) var losses: UInt64
        access(contract) var ties: UInt64
        
        /** --- Getter methods --- */
        pub fun getWins(): UInt64
        pub fun getLosses(): UInt64
        pub fun getTies(): UInt64
    }

    /// An encapsulated resource containing an array of generic moves
    /// and a getter method for those moves. Designed to be implemented
    /// in an attachment to a resource as a representation of moves assigned
    /// to a game piece.
    /// See See RockPaperScissorsGame.AssignedMoves for example implementation.
    ///
    pub resource interface AssignedMoves {
        /// Struct containing info about the related game contract
        pub let gameContractInfo: GameContractMetadata
        /// Array designed to contain an array of generic moves
        access(contract) let moves: [AnyStruct]
        
        /// Getter method returning an generic AnyStruct array
        pub fun getMoves(): [AnyStruct]

        /** Add & remove moves */
        access(contract) fun addMoves(newMoves: [AnyStruct])
        access(contract) fun removeMove(targetIdx: Int): AnyStruct?
    }
}
 