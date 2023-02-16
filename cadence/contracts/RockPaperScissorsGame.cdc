import MetadataViews from "./utility/MetadataViews.cdc"
import GamingMetadataViews from "./GamingMetadataViews.cdc"
import NonFungibleToken from "./utility/NonFungibleToken.cdc"
import GamePieceNFT from "./GamePieceNFT.cdc"
import DynamicNFT from "./DynamicNFT.cdc"

/// RockPaperScissorsGame
///
/// This contract defines the logic of a game of Rock Paper Scissors
/// and resources to support gameplay between two players as well 
/// as resources to receive and maintain gameplay Capabilities.
///
/// Gameplay occurs through Match resources in which players
/// must escrow their NFT for the length of the Match
/// or until the Match timeLimit is reached. New Matches are stored
/// in this contract's account storage to provide a neutral party
/// in which NFTs are escrowed during the course of play.
///
/// When a Match is created, MatchLobbyActions allow players to 
/// escrow their NFTs while MatchPlayerActions allows players
/// to submit their moves and request that escrowed NFTs be returned.
/// Any game assets necessary to retrieve NFT win/loss records &
/// maintain assigned moves are added to the escrowed NFTs as attachments.
///
/// To maintain the player's Capabilities, the GamePlayer
/// resource is included in this contract. GamePlayers can create new
/// Matches, but must escrow an NFT to do so (to limit spam Match
/// creation).
///
/// This contract is designed to be built upon by others in a composable
/// manner, so please create your own Matches, combine logic and Moves
/// from this game contract with other game contracts in other Matches
/// and tournaments, and get creative to build a thriving community of
/// composable games on Flow!
///
pub contract RockPaperScissorsGame {

    /// Set canonical paths for easy storage of resources in transactions
    pub let GamePlayerStoragePath: StoragePath
    pub let GamePlayerPublicPath: PublicPath
    pub let GamePlayerPrivatePath: PrivatePath
    /// Set base path as strings - will be concatenated with matchID they apply to
    pub let MatchStorageBasePathString: String
    pub let MatchPrivateBasePathString: String

    /// Name of the game
    pub let name: String
    /// Metadata about this game contract
    pub let info: GamingMetadataViews.GameContractMetadata
    /// Field that stores win/loss records for every NFT that has played this game indexed
    /// on NFT id (or UUID based on NFTv2 standards)
    access(contract) let winLossRecords: {UInt64: GamingMetadataViews.BasicWinLoss}

    /// Maintain history of completed Matches 
    access(contract) let completedMatchIDs: [UInt64]

    /// Contracts own GamePlayer for use in single player Match modes
    access(contract) let automatedGamePlayer: @GamePlayer
    access(contract) let dummyNFTID: UInt64
    /// Relevant events to watch
    pub event NewMatchCreated(gameName: String, matchID: UInt64, creatorID: UInt64, isMultiPlayer: Bool)
    pub event PlayerSignedUpForMatch(gameName: String, matchID: UInt64, addedPlayerID: UInt64)
    pub event PlayerAddedToMatch(gameName: String, matchID: UInt64, addedPlayerID: UInt64)
    pub event PlayerEscrowedNFTToMatch(
        gameName: String,
        matchID: UInt64,
        gamePlayerID: UInt64,
        nftID: UInt64,
        nftUUID: UInt64,
        numberOfNFTsInEscrow: UInt8,
        reachedEscrowCapacity: Bool
    )
    pub event MoveSubmitted(
        gameName: String,
        matchID: UInt64,
        submittingGamePlayerID: UInt64,
        totalRoundMovesSubmitted: Int
    )
    pub event MatchOver(
        gameName: String,
        matchID: UInt64,
        player1ID: UInt64,
        player1MoveRawValue: UInt8,
        player2ID: UInt64,
        player2MoveRawValue: UInt8,
        winningGamePlayer: UInt64?,
        winningNFTID: UInt64?
    )
    pub event ReturnedPlayerNFTs(
        gameName: String,
        matchID: UInt64,
        returnedNFTs: [UInt64]
    )

    /// Simple enum to identify moves
    ///
    pub enum Moves: UInt8 {
        pub case rock
        pub case paper
        pub case scissors
    }

    /// Struct to contain information about a submitted move including when
    /// it was submitted and the ID of the submitting GamePlayer
    ///
    pub struct SubmittedMove {
        pub let gamePlayerID: UInt64
        pub let move: Moves
        pub let submittedHeight: UInt64

        init(gamePlayerID: UInt64, move: Moves) {
            self.gamePlayerID = gamePlayerID
            self.move = move
            self.submittedHeight = getCurrentBlock().height
        }
    }

    /** --- WinLossRetriever Implementation --- */
    /// Resource acts as a retriever for an NFT's WinLoss data
    pub resource RPSWinLossRetriever: DynamicNFT.Attachment, MetadataViews.Resolver, GamingMetadataViews.GameResource, GamingMetadataViews.BasicWinLossRetriever {
        /// The ID of the NFT where this resource is attached (UUID by NFTv2 standards)
        pub let nftID: UInt64
        pub let nftUUID: UInt64
        /// Struct containing metadata about the attachment's related game
        pub let gameContractInfo: GamingMetadataViews.GameContractMetadata
        /// The Type this attachment is designed to be attached to
        pub let attachmentFor: [Type]

        init(nftID: UInt64, nftUUID: UInt64) {
            self.nftID = nftID
            self.nftUUID = nftUUID
            self.gameContractInfo = RockPaperScissorsGame.info
            self.attachmentFor = [Type<@{NonFungibleToken.INFT, DynamicNFT.Dynamic}>()]
        }

        /// Retrieves the WinLoss data records of the NFT where this is attached
        ///
        /// @return the GamingMetadataViews.BasicWinLoss or nil if the NFT
        ///  does not exist in the mapping of winLossRecords
        ///
        pub fun getWinLossData(): GamingMetadataViews.BasicWinLoss? {
            let winLossRecord: GamingMetadataViews.BasicWinLoss? = RockPaperScissorsGame.getWinLossRecord(nftUUID: self.nftUUID)
            return winLossRecord
        }

        /// Allows the owner to reset the WinLoss records of the NFT where this is attached
        ///
        pub fun resetWinLossData() {
            RockPaperScissorsGame.resetWinLossRecord(nftUUID: self.nftUUID)
        }

        /** --- MetadataViews.Resolver --- */
        /// Returns the Types of views that can be resolved by the resource
        ///
        pub fun getViews(): [Type] {
            return [Type<GamingMetadataViews.BasicWinLoss>()]
        }

        /// Given a supported view type, will return the view struct as AnyStruct
        ///
        pub fun resolveView(_ type: Type): AnyStruct? {
            switch type {
                case Type<GamingMetadataViews.BasicWinLoss>():
                    return self.getWinLossData()
                default:
                    return nil
            }
        }
    }

    /** --- RPSAssignedMoves --- */
    /// Resource designed to store & manage game moves. While this isn't necessarily useful
    /// in a simple game like rock, paper, scissors, the case of defining and amending moves
    /// assigned to a base resource could be helpful in deck-based games or games where
    /// available moves change regularly (i.e. between rounds or based on in-game stats).
    ///
    pub resource RPSAssignedMoves : DynamicNFT.Attachment, MetadataViews.Resolver, GamingMetadataViews.GameResource, GamingMetadataViews.AssignedMoves {
        /// The ID of the NFT where this resource is attached
        pub let nftID: UInt64
        /// Struct containing metadata about the attachment's related game
        pub let gameContractInfo: GamingMetadataViews.GameContractMetadata
        /// The Type this attachment is designed to be attached to
        pub let attachmentFor: [Type]
        /// Encapsulated generic game moves so no one can edit them except this contract
        access(contract) let moves: [AnyStruct]

        init(seedMoves: [AnyStruct], nftID: UInt64) {
            self.nftID = nftID
            self.gameContractInfo = RockPaperScissorsGame.info
            self.attachmentFor = [Type<@{NonFungibleToken.INFT, DynamicNFT.Dynamic}>()]
            self.moves = seedMoves
        }

        /** --- MetadataViews.Resolver --- */
        /// Returns the Types of views that can be resolved by the resource
        ///
        pub fun getViews(): [Type] {
            return [Type<&GamingMetadataViews.AssignedMovesView>()]
        }

        /// Given a supported view type, will return the view struct as AnyStruct
        ///
        pub fun resolveView(_ type: Type): AnyStruct? {
            switch type {
                case Type<GamingMetadataViews.AssignedMovesView>():
                    return GamingMetadataViews.AssignedMovesView(
                        gameName: RockPaperScissorsGame.name,
                        nftID: self.nftID,
                        moves: self.moves
                    )
                default:
                    return nil
            }
        }

        /** --- GamingMetadataViews.AssignedMoves --- */
        /// Getter for the generic encapsulated moves
        ///
        /// @return generic array of AnyStruct
        ///
        pub fun getMoves(): [AnyStruct] {
            return self.moves
        }

        /// Getter for the RPS game-specific encapsulated moves
        ///
        /// @return moves array as RockPaperScissorsGame.Moves
        ///
        pub fun getRPSMoves(): [Moves] {
            return self.moves as! [Moves]
        }

        /// Append the given array to stored moves array
        ///
        /// @param newMoves: Moves to be appended to self.moves
        ///
        access(contract) fun addMoves(newMoves: [AnyStruct]) {
            assert(
            newMoves as? [Moves] != nil,
            message: "Attempted to add moves to that are not compatible with this Attachment!"
            )
            self.moves.appendAll(newMoves)
        }

        /// Remove the move at the given index
        ///
        /// @param targetIdx: Index of AnyStruct to be removed from self.moves
        ///
        /// @return the AnyStruct removed at the given index if one exists, nil otherwise
        ///
        access(contract) fun removeMove(targetIdx: Int): AnyStruct? {
            if self.moves.length > targetIdx {
                return self.moves.remove(at: targetIdx)
            }
            return nil
        }
    }

    /** --- Interface to expose Player Capabilities --- */

    /// Interface exposing the ability to escrow an NFT which then returns
    /// a Capability to engage with the Match
    ///
    pub resource interface MatchLobbyActions {
        pub let id: UInt64
        pub fun getWinningNFTID(): UInt64?
        pub fun getWinningPlayerID(): UInt64?
        pub fun escrowNFTToMatch(
            nft: @AnyResource{NonFungibleToken.INFT, DynamicNFT.Dynamic},
            receiver: Capability<&{NonFungibleToken.Receiver}>,
            gamePlayerIDRef: &{GamePlayerID}
        ): Capability<&{MatchPlayerActions}>
    }

    /// Interface exposing the player's actions for a Match
    ///
    /// Through MatchPlayerActions, users can submit moves, get available moves assigned
    /// to their NFT, and call to return all escrowed NFTs to the escrowing players. A
    /// fallback method to retrieve an NFT is also included to give a user the ability
    /// to retrieve their NFT if needed.
    ///
    pub resource interface MatchPlayerActions {
        pub let id: UInt64
        pub fun getWinningNFTID(): UInt64?
        pub fun getNFTGameMoves(forPlayerID: UInt64): [Moves]?
        pub fun submitMove(move: Moves, gamePlayerIDRef: &{GamePlayerID})
        pub fun resolveMatch()
        pub fun returnPlayerNFTs(): [UInt64]
        pub fun retrieveUnclaimedNFT(
            gamePlayerIDRef: &{GamePlayerID},
            receiver: Capability<&{NonFungibleToken.Receiver}>
        ): UInt64
    }

    /// Resource defining a Match as a single round of Rock Paper Scissors
    /// between two players who must first escrow their NFTs in the
    /// Match before play can begin. Single player is also enabled so users can play
    /// by themselves, just know that it uses unsafeRandom() and has blockheight
    /// restrictions between move submission & resolution to prevent cheating.
    ///
    pub resource Match : MatchLobbyActions, MatchPlayerActions {
        /// The id of the Match is used to derive the path at which it's stored
        /// in this contract account's storage and to index associated Capabilities.
        /// It is also helpful for watching related Match events.
        pub let id: UInt64
        /// Tag defining single or multiplayer behavior for the Match
        pub let isMultiPlayer: Bool
        pub var escrowCapacity: Int
        
        /// Match timeLimit parameters defining how long the Match can escrow
        /// player NFTs before they exercise their right to have them returned.
        pub let createdTimestamp: UFix64
        pub let timeLimit: UFix64

        /// Defines whether match is still in play or not
        pub var inPlay: Bool

        /// Mapping of NFT.id to NFTs escrowed during gameplay
        access(self) let escrowedNFTs: @{UInt64: AnyResource{NonFungibleToken.INFT, DynamicNFT.Dynamic}}
        /// Track NFT associate with GamePlayer
        pub let gamePlayerIDToNFTUUID: {UInt64: UInt64}
        /// Keep Receiver Capabilities to easily return NFTs
        pub let nftReceivers: {UInt64: Capability<&{NonFungibleToken.Receiver}>}

        /// Define the allowable Moves in this Match
        pub let allowedMoves: [Moves]
        /// Maintain number of moves submitted
        access(self) let submittedMoves: {UInt64: SubmittedMove}

        /// Maintain id of winning nft
        pub var winningNFTID: UInt64?
        /// Maintain id of winning GamePlayer
        pub var winningPlayerID: UInt64?

        init(matchTimeLimit: UFix64, multiPlayer: Bool) {
            pre {
                matchTimeLimit <= UFix64(86400000): "matchTimeLimit must be less than a day (86400000 ms)"
            }
            self.id = self.uuid
            self.isMultiPlayer = multiPlayer
            if multiPlayer {
                self.escrowCapacity = 2
            } else {
                self.escrowCapacity = 1
            }
            self.inPlay = true
            self.createdTimestamp = getCurrentBlock().timestamp
            self.timeLimit = matchTimeLimit
            self.escrowedNFTs <- {}
            self.nftReceivers = {}
            self.gamePlayerIDToNFTUUID = {}
            self.allowedMoves = [
                RockPaperScissorsGame.Moves.paper,
                RockPaperScissorsGame.Moves.rock,
                RockPaperScissorsGame.Moves.scissors
            ]
            self.submittedMoves = {}
            self.winningNFTID = nil
            self.winningPlayerID = nil
        }

        /** --- MatchLobbyActions ---*/

        /// Allows for an NFT to be deposited to escrow, returning a Capability
        /// that enables the holder to engage in gameplay. Note that a single player Match
        /// only requires the actual players to escrow NFTs to avoid needing to store
        /// NFTs for the sake of automated play.
        ///
        /// @param nft: The NFT to be escrowed into the Match
        /// @param receiver: The Receiver to which the NFT will be returned
        /// after the Match is over
        /// @param playerID: The GamePlayer.id of the depositing player
        ///
        /// @return MatchPlayerActions Capability for this Match
        ///
        pub fun escrowNFTToMatch(
            nft: @AnyResource{NonFungibleToken.INFT, DynamicNFT.Dynamic},
            receiver: Capability<&{NonFungibleToken.Receiver}>,
            gamePlayerIDRef: &{GamePlayerID}
        ): Capability<&{MatchPlayerActions}> {
            pre {
                !self.gamePlayerIDToNFTUUID.containsKey(gamePlayerIDRef.id):
                    "Player has already joined this Match!"
                self.escrowedNFTs.length < self.escrowCapacity:
                    "Both players have already escrowed their NFTs, Match is full!"
                !self.escrowedNFTs.containsKey(nft.id):
                    "NFT with id ".concat(nft.id.toString()).concat(" already in escrow!")
                self.inPlay == true:
                    "Match is over!"
                receiver.check():
                    "Given Receiver Capability is not valid!"
            }
            post {
                RockPaperScissorsGame.movesEqual(
                    self.getNFTGameMoves(
                        forPlayerID: gamePlayerIDRef.id
                    )!, self.allowedMoves
                ):
                    "Moves improperly assigned to escrowed NFT!"
            }

            // Get MatchPlayerActions Capability from contract account's storage
            let matchPrivatePath = RockPaperScissorsGame.getMatchPrivatePath(self.id)
            let matchPlayerActionsCap = RockPaperScissorsGame.account
                .getCapability<&{
                    MatchPlayerActions
                }>(
                    matchPrivatePath
                )
            // Check the Capability is valid
            assert(
                matchPlayerActionsCap.check(),
                message: "Problem retrieving Match's MatchPlayerActions Capability!"
            )

            let nftID: UInt64 = nft.id
            let nftUUID: UInt64 = nft.uuid

            // Insert GamingMetadataViews.BasicWinLoss for this game
            // Check for existing record occurs in function definition
            RockPaperScissorsGame.insertWinLossRecord(nftUUID: nftUUID)

            // Ensure the NFT has a way to retrieve win/loss data with a GamingMetadataViews.BasicWinLossRetriever attachment
            if !nft.hasAttachmentType(Type<@RockPaperScissorsGame.RPSWinLossRetriever>()) {
                let retriever <- create RockPaperScissorsGame.RPSWinLossRetriever(nftID: nftID, nftUUID: nftUUID)
                nft.addAttachment(<-retriever)
            }

            // See if the NFT has moves for this game
            if !nft.hasAttachmentType(Type<@RockPaperScissorsGame.RPSAssignedMoves>()) {
                // Add the AssignedMoves attachment to the NFT
                let moves <- create RockPaperScissorsGame.RPSAssignedMoves(
                        seedMoves: self.allowedMoves,
                        nftID: nftID
                    )
                nft.addAttachment(<-moves)
            }

            // Then store player's NFT & Receiver
            self.escrowedNFTs[nftUUID] <-! nft
            self.nftReceivers.insert(key: nftUUID, receiver)

            // Maintain association of this NFT with the depositing GamePlayer
            self.gamePlayerIDToNFTUUID.insert(key: gamePlayerIDRef.id, nftUUID)

            // Ensure the NFT was added to escrow properly
            assert(
                &self.escrowedNFTs[nftUUID] as &{NonFungibleToken.INFT}? != nil,
                message: "NFT was not successfully added to escrow!"
            )

            emit PlayerEscrowedNFTToMatch(
                gameName: RockPaperScissorsGame.name,
                matchID: self.id,
                gamePlayerID: gamePlayerIDRef.id,
                nftID: nftID,
                nftUUID: nftUUID,
                numberOfNFTsInEscrow: UInt8(self.escrowedNFTs.length),
                reachedEscrowCapacity: self.escrowedNFTs.length == self.escrowCapacity
            )

            return matchPlayerActionsCap
        }

        /* --- MatchLobbyActions & MatchPlayerActions --- */
        /// Getter to retrieve the winning player ID for the match
        ///
        pub fun getWinningNFTID(): UInt64? {
            pre {
                !self.inPlay:
                    "Match must be resolved before a winner is determined"
            }
            return self.winningNFTID
        }

        /// Getter to retrieve the winning NFT ID for the match
        ///
        pub fun getWinningPlayerID(): UInt64? {
            pre {
                !self.inPlay:
                    "Match must be resolved before a winner is determined"
            }
            return self.winningPlayerID
        }

        /** --- MatchPlayerActions --- */

        /// Allows the caller to retrieve the moves assigned to the NFT
        /// deposited by the given GamePlayer.id
        pub fun getNFTGameMoves(forPlayerID: UInt64): [Moves]? {
            // Get a reference to their escrowed NFT
            if let playerNFTID = self.gamePlayerIDToNFTUUID[forPlayerID] {
                if let nftRef = &self.escrowedNFTs[playerNFTID] as &{NonFungibleToken.INFT, DynamicNFT.Dynamic}? {
                    // Get a reference to the NFT's AssignedMoves attachment
                    if let attachmentRef = nftRef.getAttachmentRef(
                            Type<@RockPaperScissorsGame.RPSAssignedMoves>()
                        ) {
                        let assignedMovesRef = attachmentRef as! &RockPaperScissorsGame.RPSAssignedMoves
                        return assignedMovesRef.moves as! [Moves]
                    }
                    return nil
                }
            }
            return nil
        }

        /// Function allows players to submit their moves to the match.
        ///
        /// Note that to submit moves, a reference to a GamePlayer's
        /// GamePlayerID must be provided. This is due to the fact that both
        /// GamePlayers have the same MatchPlayerActions Capability. If we simply
        /// asked for the GamePlayer's id as a provided argument, we couldn't trust they
        /// would be honest, so the Match asks for a reference that only the submitting
        /// GamePlayer should be able to provide.
        ///
        /// @param moves: a mapping of nft.id to Moves (rock, paper, or scissors)
        /// with the expectation that there are exactly two entries
        ///
        pub fun submitMove(move: Moves, gamePlayerIDRef: &{GamePlayerID}) {
            pre {
                self.escrowedNFTs.length == self.escrowCapacity:
                    "Both players must escrow NFTs before play begins!"
                self.gamePlayerIDToNFTUUID.containsKey(gamePlayerIDRef.id) ||
                (
                    gamePlayerIDRef.id == RockPaperScissorsGame.automatedGamePlayer.id &&
                    !self.isMultiPlayer
                ):
                    "Player is not associated with this Match!"
                gamePlayerIDRef.id != RockPaperScissorsGame.automatedGamePlayer.id ||
                (
                    gamePlayerIDRef.id == RockPaperScissorsGame.automatedGamePlayer.id &&
                    self.submittedMoves.length == 1 &&
                    !self.isMultiPlayer
                ):
                    "Player must submit move before automated player in single-player mode!"
                !self.submittedMoves.containsKey(RockPaperScissorsGame.automatedGamePlayer.id):
                    "Player cannot submit move after automated player!"
                !self.submittedMoves.containsKey(gamePlayerIDRef.id):
                    "Player has already submitted move for this Match!"
                self.submittedMoves.length < 2:
                    "Both moves have already been submitted for this Match!"
                gamePlayerIDRef.id == RockPaperScissorsGame.automatedGamePlayer.id ||
                self.getNFTGameMoves(forPlayerID: gamePlayerIDRef.id)!.contains(move):
                    "Player's NFT does not have the submitted move available to play!"
                self.inPlay == true:
                    "Match is not in play any longer!"
            }

            // Add the move to the mapping of submitted moves indexed by the
            // submitting player's GamePlayerID.id
            self.submittedMoves.insert(
                key: gamePlayerIDRef.id, 
                SubmittedMove(
                    gamePlayerID: gamePlayerIDRef.id,
                    move: move
            ))

            emit MoveSubmitted(
                gameName: RockPaperScissorsGame.name,
                matchID: self.id,
                submittingGamePlayerID: gamePlayerIDRef.id,
                totalRoundMovesSubmitted: self.submittedMoves.length
            )
        }

        /// This function resolves the Match, demanding that both player moves have been
        /// submitted for resolution to occur
        ///
        pub fun resolveMatch() {
            pre {
                self.submittedMoves.length == 2:
                    "Both players must submit moves before the Match can be resolved!"
                self.inPlay == true:
                    "Match is not in play any longer!"
            }

            // Ensure that match resolution is not called in the same transaction as either move submission
            // to prevent cheating
            assert(
                getCurrentBlock().height > self.submittedMoves[self.submittedMoves.keys[0]]!.submittedHeight &&
                getCurrentBlock().height > self.submittedMoves[self.submittedMoves.keys[1]]!.submittedHeight,
                message: "Too soon after move submission to resolve the match!"
            )
            // Determine the ids of winning GamePlayer.id & NFT.id
            self.winningPlayerID = RockPaperScissorsGame
                .determineRockPaperScissorsWinner(
                    moves: self.submittedMoves
                )
            // Assign winningNFTID to NFT submitted by the winning GamePlayer
            if self.winningPlayerID != nil && self.winningPlayerID != RockPaperScissorsGame.automatedGamePlayer.id {
                self.winningNFTID = self.gamePlayerIDToNFTUUID[self.winningPlayerID!]!
            // If the winning player is the contract's automated player, assign the winningNFTID 
            // to the contract's dummyNFTID
            } else if self.winningPlayerID == RockPaperScissorsGame.automatedGamePlayer.id {
                self.winningNFTID = RockPaperScissorsGame.dummyNFTID
            }

            // Ammend NFTs win/loss data
            for nftID in self.escrowedNFTs.keys {
                RockPaperScissorsGame.updateWinLossRecord(
                    nftUUID: nftID,
                    winner: self.winningNFTID
                )
            }

            // Mark the Match as no longer in play
            self.inPlay = false

            // Announce the Match results
            let player1ID = self.submittedMoves.keys[0]
            let player2ID = self.submittedMoves.keys[1]
            emit MatchOver(
                gameName: RockPaperScissorsGame.name,
                matchID: self.id,
                player1ID: player1ID,
                player1MoveRawValue: self.submittedMoves[player1ID]!.move.rawValue,
                player2ID: player2ID,
                player2MoveRawValue: self.submittedMoves[player2ID]!.move.rawValue,
                winningGamePlayer: self.winningPlayerID,
                winningNFTID: self.winningNFTID
            )
        }

        /** --- MatchLobbyActions & MatchPlayerActions --- */

        /// Can be called by any interface if there's a timeLimit or assets weren't returned
        /// for some reason
        ///
        /// @return An array containing the nft.ids of all NFTs returned to their owners
        ///
        pub fun returnPlayerNFTs(): [UInt64] {
            pre {
                getCurrentBlock().timestamp >= self.createdTimestamp + self.timeLimit ||
                self.inPlay == false:
                    "Cannot return NFTs while Match is still in play!"
            }

            let returnedNFTs: [UInt64] = []
            // Written so that issues with one player's Receiver won't affect the return of
            // any other player's NFT
            for id in self.nftReceivers.keys {
                if let receiverCap: Capability<&{NonFungibleToken.Receiver}> = self.nftReceivers[id] {
                    if let receiverRef = receiverCap.borrow() {
                        // We know we have the proper Receiver reference, so we'll now move the token & deposit
                        if let token <- self.escrowedNFTs.remove(key: id) as! @NonFungibleToken.NFT? {
                            receiverRef.deposit(token: <- token)
                            returnedNFTs.append(id)
                        }
                    }
                }
            }
            // Set inPlay to false in case Match timed out
            self.inPlay = false
            // Add the id of this Match to the history of completed Matches
            // as long as all it does not contain NFTs. Doing so allows the Match to be
            // destroyed to clean up contract account storage
            if self.escrowedNFTs.length == 0 {
                RockPaperScissorsGame.completedMatchIDs.append(self.id)
            }

            emit ReturnedPlayerNFTs(
                gameName: RockPaperScissorsGame.name,
                matchID: self.id,
                returnedNFTs: returnedNFTs
            )
            
            // Return an array containing ids of the successfully returned NFTs
            return returnedNFTs
        }

        /// Function to enable a player to retrieve their NFT should they need to due to failure in
        /// the returnPlayerNFTs() method
        ///
        /// @param gamePlayerIDRef: Reference to the player's GamePlayerID
        /// @param receiver: A Receiver Capability to a resource the NFT will be deposited to
        ///
        pub fun retrieveUnclaimedNFT(
            gamePlayerIDRef: &{GamePlayerID},
            receiver: Capability<&{NonFungibleToken.Receiver}>
        ): UInt64 {
            pre {
                getCurrentBlock().timestamp >= self.createdTimestamp + self.timeLimit ||
                self.inPlay == false:
                    "Cannot return NFTs while Match is still in play!"
                self.gamePlayerIDToNFTUUID.containsKey(gamePlayerIDRef.id):
                    "This GamePlayer is not associated with this Match!"
                self.escrowedNFTs.containsKey(self.gamePlayerIDToNFTUUID[gamePlayerIDRef.id]!):
                    "Player does not have any NFTs escrowed in this Match!"
                receiver.check():
                    "Could not borrow reference to provided Receiver in retrieveUnclaimedNFT()!"
            }
            // Get the NFT from escrow
            let nftID = self.gamePlayerIDToNFTUUID[gamePlayerIDRef.id]!
            let nft <- (self.escrowedNFTs.remove(key: nftID) as! @NonFungibleToken.NFT?)!
            
            // Return the NFT to the given Receiver
            receiver.borrow()!.deposit(token: <-nft)

            // Set inPlay to false in case Match timed out and it wasn't marked
            self.inPlay = false
            // Add the id of this Match to the history of completed Matches
            // as long as all it does not contain NFTs. Doing so allows the Match to be
            // destroyed to clean up contract account storage
            if self.escrowedNFTs.length == 0 {
                RockPaperScissorsGame.completedMatchIDs.append(self.id)
            }

            emit ReturnedPlayerNFTs(
                gameName: RockPaperScissorsGame.name,
                matchID: self.id,
                returnedNFTs: [nftID]
            )

            return nftID
        }

        /** --- Match --- */

        /// Retrieves the submitted moves for the Match, allowing for review of historical gameplay
        ///
        /// @return the mapping of GamePlayerID to SubmittedMove
        ///
        access(contract) fun getSubmittedMoves(): {UInt64: SubmittedMove} {
            pre {
                !self.inPlay:
                    "Cannot get submitted moves until Match is complete!"
            }
            return self.submittedMoves
        }
        
        /// Custom destroyer to prevent destroying escrowed NFTs
        destroy() {
            pre {
                self.escrowedNFTs.length == 0:
                    "Cannot destroy while NFTs in escrow!"
                getCurrentBlock().timestamp >= self.createdTimestamp + self.timeLimit ||
                self.inPlay == false: 
                    "Cannot destroy while Match is still in play!"
            }
            destroy self.escrowedNFTs
        }
    }

    /** --- Player Related Interfaces --- */

    /// A simple interface a player would use to demonstrate that they are
    /// the given ID
    ///
    pub resource interface GamePlayerID {
        pub let id: UInt64
    }

    /// Public interface allowing others to add GamePlayer to matches. Of course, there is
    /// no obligation for matches to be played, but this makes it so that other players
    /// each other to a Match       
    ///
    pub resource interface GamePlayerPublic {
        pub let id: UInt64
        pub fun addMatchLobbyActionsCapability(
            matchID: UInt64,
            _ cap: Capability<&{MatchLobbyActions}>
        )
        pub fun getAvailableMoves(matchID: UInt64): [Moves]?
        pub fun getMatchesInLobby(): [UInt64]
        pub fun getMatchesInPlay(): [UInt64]
    }

    /// A resource interface allowing a user to delegate use of their GamePlayer
    /// via Capability
    ///
    pub resource interface DelegatedGamePlayer {
        pub let id: UInt64
        pub let gameContractInfo: GamingMetadataViews.GameContractMetadata
        pub fun getGamePlayerIDRef(): &{GamePlayerID}
        pub fun getAvailableMoves(matchID: UInt64): [Moves]
        pub fun getMatchesInLobby(): [UInt64]
        pub fun getMatchesInPlay(): [UInt64]
        pub fun getMatchLobbyCaps(): {UInt64: Capability<&{MatchLobbyActions}>}
        pub fun getMatchPlayerCaps(): {UInt64: Capability<&{MatchPlayerActions}>}
        pub fun deleteLobbyActionsCapability(matchID: UInt64)
        pub fun deletePlayerActionsCapability(matchID: UInt64)
        pub fun createMatch(
            multiPlayer: Bool,
            matchTimeLimit: UFix64,
            nft: @AnyResource{NonFungibleToken.INFT},
            receiverCap: Capability<&{NonFungibleToken.Receiver}>
        ): UInt64
        pub fun signUpForMatch(matchID: UInt64)
        pub fun depositNFTToMatchEscrow(
            nft: @AnyResource{NonFungibleToken.INFT, DynamicNFT.Dynamic},
            matchID: UInt64,
            receiverCap: Capability<&{NonFungibleToken.Receiver}>
        )
        pub fun submitMoveToMatch(matchID: UInt64, move: Moves)
        pub fun addPlayerToMatch(matchID: UInt64, gamePlayerRef: &AnyResource{GamePlayerPublic})
        pub fun resolveMatchByID(_ id: UInt64)
        pub fun addMatchLobbyActionsCapability(matchID: UInt64, _ cap: Capability<&{MatchLobbyActions}>)
    }

    /** --- Receiver for Match Capabilities --- */

    /// Resource that maintains all the player's MatchPlayerActions capabilities
    /// Players can add themselves to games or be added if they expose GamePlayerPublic
    /// capability
    ///
    pub resource GamePlayer : GamePlayerID, GamePlayerPublic {
        pub let id: UInt64
        access(self) let matchLobbyCapabilities: {UInt64: Capability<&{MatchLobbyActions}>}
        access(self) let matchPlayerCapabilities: {UInt64: Capability<&{MatchPlayerActions}>}

        init() {
            self.id = self.uuid
            self.matchPlayerCapabilities = {}
            self.matchLobbyCapabilities = {}
        }
        
        /** --- GamePlayer --- */

        /// Returns a reference to this resource as GamePlayerID
        ///
        /// @return reference to this GamePlayer's GamePlayerID Capability
        ///
        pub fun getGamePlayerIDRef(): &{GamePlayerID} {
            return &self as &{GamePlayerID}
        }

        /// Getter for the GamePlayer's available moves assigned to their escrowed NFT
        ///
        /// @param matchID: Match.id for which they are querying
        ///
        /// @return the Moves assigned to their escrowed NFT
        ///
        pub fun getAvailableMoves(matchID: UInt64): [Moves]? {
            pre {
                self.matchPlayerCapabilities[matchID] != nil:
                    "Player is not engaged with the given Match"
                self.matchPlayerCapabilities[matchID]!.check():
                    "Problem with MatchPlayerMoves Capability for given Match.id!"
            }
            let matchCap = self.matchPlayerCapabilities[matchID]!
            return matchCap.borrow()!.getNFTGameMoves(forPlayerID: self.id)
        }

        /// Getter for the ids of Matches for which player has MatchLobbyActions Capabilies
        ///
        /// @return ids of Matches for which player has MatchLobbyActions Capabilies
        ///
        pub fun getMatchesInLobby(): [UInt64] {
            return self.matchLobbyCapabilities.keys
        }

        /// Getter for the ids of Matches for which player has MatchPlayerActions Capabilies
        ///
        /// @return ids of Matches for which player has MatchPlayerActions Capabilies
        ///
        pub fun getMatchesInPlay(): [UInt64] {
            return self.matchPlayerCapabilities.keys
        }

        /// Simple getter for mapping of MatchLobbyActions Capabilities
        ///
        /// @return mapping of Match.id to MatchLobbyActions Capabilities
        ///
        pub fun getMatchLobbyCaps(): {UInt64: Capability<&{MatchLobbyActions}>} {
            return self.matchLobbyCapabilities
        }

        /// Simple getter for mapping of MatchPlayerActions Capabilities
        ///
        /// @return mapping of Match.id to MatchPlayerActions Capabilities
        ///
        pub fun getMatchPlayerCaps(): {UInt64: Capability<&{MatchPlayerActions}>} {
            return self.matchPlayerCapabilities
        }

        /// Allows GamePlayer to delete capabilities from their mapping to free up space used
        /// by old matches.
        ///
        /// @param matchID: The id for the MatchLobbyActions Capability that the GamePlayer 
        /// would like to delete from their matchLobbyCapabilities
        ///
        pub fun deleteLobbyActionsCapability(matchID: UInt64) {
            self.matchLobbyCapabilities.remove(key: matchID)
        }

        /// Allows GamePlayer to delete capabilities from their mapping to free up space used
        /// by old matches.
        ///
        /// @param matchID: The id for the MatchPlayerActions Capability that the GamePlayer 
        /// would like to delete from their matchPlayerCapabilities
        ///
        pub fun deletePlayerActionsCapability(matchID: UInt64) {
            self.matchPlayerCapabilities.remove(key: matchID)
        }

        /// Creates a new Match resource, saving it in the contract account's storage
        /// and linking MatchPlayerActions at a dynamic path derived with the Match.id.
        /// Creating a match requires an NFT and Receiver Capability to mitigate spam
        /// vector where an attacker creates an exorbitant number of Matches.
        ///
        /// @param matchTimeLimit: Time before players have right to retrieve their
        /// escrowed NFTs
        /// 
        /// @return: Match.id of the newly created Match
        ///
        pub fun createMatch(
            multiPlayer: Bool,
            matchTimeLimit: UFix64,
            nft: @AnyResource{NonFungibleToken.INFT, DynamicNFT.Dynamic},
            receiverCap: Capability<&{NonFungibleToken.Receiver}>
        ): UInt64 {
            pre {
                receiverCap.check(): 
                    "Problem with provided Receiver Capability!"
            }
            // Create the new match & preserve its ID
            let newMatch <- create Match(matchTimeLimit: matchTimeLimit, multiPlayer: multiPlayer)
            let newMatchID = newMatch.id
            
            // Derive paths using matchID
            let matchStoragePath = RockPaperScissorsGame.getMatchStoragePath(newMatchID)
            let matchPrivatePath = RockPaperScissorsGame.getMatchPrivatePath(newMatchID)
            
            // Save the match to game contract account's storage
            RockPaperScissorsGame.account.save(<-newMatch, to: matchStoragePath)
            
            // Link each Capability to game contract account's private
            RockPaperScissorsGame.account.link<&{
                MatchLobbyActions,
                MatchPlayerActions
            }>(
                matchPrivatePath,
                target: matchStoragePath
            )

            // Get the MatchLobbyActions Capability we just linked
            let lobbyCap = RockPaperScissorsGame.account
                .getCapability<&{
                    MatchLobbyActions
                }>(
                    matchPrivatePath
                )
            // Add that Capability to the GamePlayer's mapping
            self.matchLobbyCapabilities[newMatchID] = lobbyCap

            // Deposit the specified NFT to the new Match & return the Match.id
            self.depositNFTToMatchEscrow(nft: <-nft, matchID: newMatchID, receiverCap: receiverCap)

            // Remove the MatchLobbyActions now that the NFT has been escrowed & return the Match.id
            self.matchLobbyCapabilities.remove(key: newMatchID)

            emit NewMatchCreated(
                gameName: RockPaperScissorsGame.name,
                matchID: newMatchID,
                creatorID: self.id,
                isMultiPlayer: multiPlayer
            )
            return newMatchID
        }

        /// Allows for GamePlayer to sign up for a match that already exists. Doing so retrieves the 
        /// MatchPlayerActions Capability from the contract account's private storage and add
        /// it to the GamePlayers mapping of Capabilities.
        ///
        /// @param matchID: The id of the Match for which they want to retrieve the
        /// MatchPlayerActions Capability
        ///
        pub fun signUpForMatch(matchID: UInt64) {
            // Derive path to capability
            let matchPrivatePath = PrivatePath(identifier: RockPaperScissorsGame
                .MatchPrivateBasePathString.concat(matchID.toString()))!
            // Get the Capability
            let matchLobbyActionsCap = RockPaperScissorsGame.account
                .getCapability<&{MatchLobbyActions}>(matchPrivatePath)

            // Ensure Capability is not nil
            assert(
                matchLobbyActionsCap.check(),
                message: "Not able to retrieve MatchLobbyActions Capability for given matchID!"
            )

            // Add it to the mapping
            self.matchLobbyCapabilities.insert(key: matchID, matchLobbyActionsCap)

            emit PlayerSignedUpForMatch(gameName: RockPaperScissorsGame.name, matchID: matchID, addedPlayerID: self.id)
        }

        /// Allows for NFTs to be taken from GamePlayer's Collection and escrowed into the given Match.id
        /// using the MatchPlayerActions Capability already in their mapping
        ///
        /// @param nft: The NFT to be escrowed
        /// @param matchID: The id of the Match into which the NFT will be escrowed
        /// @param receiverCap: The Receiver Capability to which the NFT will be returned
        ///
        pub fun depositNFTToMatchEscrow(
            nft: @AnyResource{NonFungibleToken.INFT, DynamicNFT.Dynamic},
            matchID: UInt64,
            receiverCap: Capability<&{NonFungibleToken.Receiver}>
        ) {
            pre {
                receiverCap.check(): 
                    "Problem with provided Receiver Capability!"
                self.matchLobbyCapabilities.containsKey(matchID) &&
                !self.matchPlayerCapabilities.containsKey(matchID):
                    "GamePlayer does not have the Capability to play this Match!"
            }
            post {
                self.matchPlayerCapabilities.containsKey(matchID):
                    "MatchPlayerActions Capability not successfully added!"
                !self.matchLobbyCapabilities.containsKey(matchID) &&
                self.matchPlayerCapabilities.containsKey(matchID):
                    "GamePlayer does not have the Capability to play this Match!"
            }
            
            // Ensure the Capability is valid
            assert(
                receiverCap.check(),
                message: "Could not access Receiver Capability at the given path for this account!"
            )
            
            // Get the MatchPlayerActions Capability from this GamePlayer's mapping
            let matchLobbyCap: Capability<&{MatchLobbyActions}> = self.matchLobbyCapabilities[matchID]!
            let matchLobbyActionsRef = matchLobbyCap
                .borrow()
                ?? panic("Could not borrow reference to MatchPlayerActions")

            // Escrow the NFT to the Match, getting back a Capability
            let playerActionsCap: Capability<&{MatchPlayerActions}> = matchLobbyActionsRef
                .escrowNFTToMatch(
                    nft: <-nft,
                    receiver: receiverCap,
                    gamePlayerIDRef: &self as &{GamePlayerID}
                )
            // Add that Capability to the GamePlayer's mapping & remove from
            // mapping of MatchLobbyCapabilities
            self.matchPlayerCapabilities.insert(key: matchID, playerActionsCap)
            self.matchLobbyCapabilities.remove(key: matchID)
        }

        /// Allows the GamePlayer to submit a move to the provided Match.id
        ///
        /// @param matchID: Match.id of the Match into which the move will be submitted
        /// @param move: The move to be played
        ///
        pub fun submitMoveToMatch(matchID: UInt64, move: Moves) {
            pre {
                self.matchPlayerCapabilities.containsKey(matchID):
                    "Player does not have the ability to play this Match!"
                self.matchPlayerCapabilities[matchID]!.check():
                    "Problem with the MatchPlayerActions Capability for given Match!"
            }
            let matchRef = self.matchPlayerCapabilities[matchID]!.borrow()!
            let gamePlayerIDRef = self.getGamePlayerIDRef()
            matchRef.submitMove(move: move, gamePlayerIDRef: gamePlayerIDRef)
        }

        /// Adds the referenced GamePlayer to the Match defined by the given Match.id by retrieving
        /// the associated Match's MatchPlayerActions Capability and passing it as a parameter to
        /// GamePlayerPublic.addMatchPlayerActionsCapability() along with the Match.id
        ///
        /// @param matchID: The id of the associated Match
        /// @param gamePlayerRef: Reference to GamePlayerPublic that will receive
        /// a MatchPlayerResource Capability
        ///
        pub fun addPlayerToMatch(matchID: UInt64, gamePlayerRef: &AnyResource{GamePlayerPublic}) {
            // Derive match's private path from matchID
            let matchPrivatePath = RockPaperScissorsGame.getMatchPrivatePath(matchID)
            // Get the capability
            let matchLobbyActionsCap: Capability<&AnyResource{MatchLobbyActions}> = RockPaperScissorsGame.account
                .getCapability<&{MatchLobbyActions}>(matchPrivatePath)

            // Ensure we actually got the Capability we need
            assert(
                matchLobbyActionsCap.check(),
                message: "Not able to retrieve MatchPlayerActions Capability for given matchID"
            )

            // Add it to the player's matchPlayerCapabilities
            gamePlayerRef.addMatchLobbyActionsCapability(matchID: matchID, matchLobbyActionsCap)
        }

        /// This method allows a player to call for a match to be resolved. Note that the called 
        /// method Match.resolveMatch() requires that both moves be submitted for resolution to occur
        /// and that the method be called at least one block after the last move was submitted.
        ///
        /// @param id: The id of the Match to be resolved.
        ///
        pub fun resolveMatchByID(_ id: UInt64) {
            pre {
                self.matchPlayerCapabilities.containsKey(id):
                    "Player does not have the ability to play this Match!"
                self.matchPlayerCapabilities[id]!.check():
                    "Problem with the MatchPlayerActions Capability for given Match!"
            }
            let matchRef = self.matchPlayerCapabilities[id]!.borrow()!
            let gamePlayerIDRef = self.getGamePlayerIDRef()
            matchRef.resolveMatch()
        }

        /** --- GamePlayerPublic --- */

        /// Allows others to add MatchPlayerActions Capabilities to their mapping for ease of Match setup.
        ///
        /// @param matchID: The id associated with the MatchPlayerActions the GamePlayer is being given access
        /// @param cap: The MatchPlayerActions Capability for which the GamePlayer is being given access
        ///
        pub fun addMatchLobbyActionsCapability(matchID: UInt64, _ cap: Capability<&{MatchLobbyActions}>) {
            pre {
                !self.matchLobbyCapabilities.containsKey(matchID) && !self.matchPlayerCapabilities.containsKey(matchID):
                    "Player already has capability for this Match!"
            }
            post {
                self.matchLobbyCapabilities.containsKey(matchID): "Capability for match has not been saved into player"
            }

            self.matchLobbyCapabilities.insert(key: matchID, cap)
            // Event that could be used to notify player they were added
            emit PlayerAddedToMatch(gameName: RockPaperScissorsGame.name, matchID: matchID, addedPlayerID: self.id)
        }
    }

    /** --- Contract helper functions --- */

    /// Getter to identify the contract's automated GamePlayer.id
    ///
    /// @return the id of the contract's GamePlayer used for singleplayer Matches
    ///    
    pub fun getAutomatedPlayerID(): UInt64 {
        return self.automatedGamePlayer.id
    }

    /// Getter to identify the contract's dummyNFTID
    ///
    /// @return the contract's dummyNFTID used for singleplayer Matches
    ///
    pub fun getDummyNFTID(): UInt64 {
        return self.dummyNFTID
    }

    /// Create a GamePlayer resource
    ///
    /// @return a fresh GamePlayer resource
    ///
    pub fun createGamePlayer(): @GamePlayer {
        return <- create GamePlayer()
    }

    /// Method to determine outcome of a RockPaperScissors with given moves
    /// Exposing game logic allows for some degree of composability with other
    /// games and match types
    ///
    /// @param moves: a mapping of GamePlayer.id to Moves (rock, paper, or scissors)
    /// with the expectation that there are exactly two entries
    ///
    /// @return the id of the winning GamePlayer or nil if result is a tie
    ///
    pub fun determineRockPaperScissorsWinner(moves: {UInt64: SubmittedMove}): UInt64? {
        pre {
            moves.length == 2: "RockPaperScissors requires two moves"
        }
        
        let player1 = moves.keys[0]
        let player2 = moves.keys[1]

        // Choose one move to compare against other
        switch moves[player1]!.move {
            case RockPaperScissorsGame.Moves.rock:
                if moves[player2]!.move == RockPaperScissorsGame.Moves.paper {
                    return player2
                } else if moves[player2]!.move == RockPaperScissorsGame.Moves.scissors {
                    return player1
                }
            case RockPaperScissorsGame.Moves.paper:
                if moves[player2]!.move == RockPaperScissorsGame.Moves.rock {
                    return player1
                } else if moves[player2]!.move == RockPaperScissorsGame.Moves.scissors {
                    return player2
                }
            case RockPaperScissorsGame.Moves.scissors:
                if moves[player2]!.move == RockPaperScissorsGame.Moves.rock {
                    return player2
                } else if moves[player2]!.move == RockPaperScissorsGame.Moves.paper {
                    return player1
                }
        }
        // If they played the same move, it's a tie -> return nil
        return nil
    }

    /// Get GamingMetadataViews.BasicWinLoss for a certain NFT 
    ///
    /// @param: nftUUID: uuid of associated NFT in winLossRecords (nft.id based on updated NFTv2 standard)
    ///
    pub fun getWinLossRecord(nftUUID: UInt64): GamingMetadataViews.BasicWinLoss? {
        return self.winLossRecords[nftUUID]
    }

    /// Getter method for winLossRecords
    ///
    /// @return A Mapping of GamingMetadataViews.BasicWinLoss struct defining the
    /// total win/loss/tie record of the nft.uuid (nft.id based on updated NFTv2 standard)
    /// on which it's indexed
    ///
    pub fun getTotalWinLossRecords(): {UInt64: GamingMetadataViews.BasicWinLoss} {
        return self.winLossRecords
    }

    /// Getter method for historical gameplay history on a specified Match
    ///
    /// @param id: the Match.id for which the mapping is to be retrieved
    ///
    /// @return a mapping of GamePlayerID to SubmittedMove for the given Match or nil
    /// if the Match does not exist in storage
    ///
    pub fun getMatchMoveHistory(id: UInt64): {UInt64: SubmittedMove}? {
        let matchPath = self.getMatchStoragePath(id)!
        if let matchRef = self.account.borrow<&Match>(from: matchPath) {
            return matchRef.getSubmittedMoves()
        }
        return nil
    }

    /// Function for easy derivation of a Match's StoragePath. Provides no guarantees
    /// that a Match is stored there.
    ///
    /// @param matchID: the id of the target Match
    ///
    /// @return the StoragePath where that Match would be stored
    ///
    pub fun getMatchStoragePath(_ matchID: UInt64): StoragePath {
        let identifier = self.MatchStorageBasePathString.concat(matchID.toString())
        return StoragePath(identifier: identifier)!
    }

    /// Function for easy derivation of a Match's PrivatePath. Provides no guarantees
    /// that a Match is stored there.
    ///
    /// @param matchID: the id of the target Match
    ///
    /// @return the PrivatePath where that Match would be stored
    ///
    pub fun getMatchPrivatePath(_ matchID: UInt64): PrivatePath {
        let identifier = self.MatchStorageBasePathString.concat(matchID.toString())
        return PrivatePath(identifier: identifier)!
    }

    /// Enable submission of random move to single player Match. To make randomness a bit safer,
    /// this should be run in a separate transaction than the player's move is submitted.
    ///
    /// @param matchID: The id for the Match to which the random move will be submitted
    ///
    pub fun submitAutomatedPlayerMove(matchID: UInt64) {
        // Assign a random move
        let randomMove = Moves(
                rawValue: UInt8(unsafeRandom() % 3)
            ) ?? panic("Random move does not map to a legal RockPaperScissorsGame.Moves value!")
        // Get the Match
        let matchStoragePath = self.getMatchStoragePath(matchID)
        let matchRef = self.account
            .borrow<&{
                MatchPlayerActions
            }>(
                from: matchStoragePath
            ) ?? panic("Could not get MatchPlayerActions reference for given Match!")
        matchRef.submitMove(move: randomMove, gamePlayerIDRef: &self.automatedGamePlayer as &{GamePlayerID})
    }

    /// Helper method to compare arrays of Moves
    ///
    /// @param first: one array of Moves
    /// @param second: other array of Moves
    ///
    /// @return true if the two arrays are equal, false otherwise
    ///
    pub fun movesEqual(_ first: [Moves], _ second: [Moves]): Bool {
        // Return false if they have differing lengths
        if first.length != second.length {
            return false
        }
        // With same length we can compare their elements
        for idx, move in first {
            // Compare elements at each index are contained in the other
            if !second.contains(move) || !first.contains(second[idx]) {
                return false
            }
        }
        // Passed all non-equal cases so must be equal
        return true
    }

    /// Utility function allowing the public to clean up Matches that are no 
    /// longer necessary, helping to reduce contract's storage usage
    ///
    pub fun destroyCompletedMatches(): [UInt64] {
        
        let destroyedMatchIDs: [UInt64] = []
        // Iterate through completedMatchIDs
        for matchID in self.completedMatchIDs {
            // Derive the StoragePath of the Match with given id
            let matchStoragePath = self.getMatchStoragePath(matchID)
                
            // Load and destroy the Match
            let completedMatch <- self.account.load<@Match>(from: matchStoragePath)
            destroy completedMatch
            
            // Remove the id of the destroyed Match, adding to array
            // maintaining destroyed IDs
            destroyedMatchIDs.append(self.completedMatchIDs.removeFirst())
        }
        // Return the IDs of the destroyed Matches
        return destroyedMatchIDs
    }

    /// Inserts a WinLoss record into the winLossRecords mapping if one does
    /// not already exist for the given nft.id
    ///
    /// @param nftUUID: uuid of the NFT (nft.id based on updated NFTv2 standard) 
    /// for which a GamingMetadataViews.BasicWinLoss will be indexed into the
    /// contract's historical winLossRecords mapping
    ///
    access(contract) fun insertWinLossRecord(nftUUID: UInt64) {
        // Before inserting, make sure there is not already a record for the
        // given nftUUID
        if self.winLossRecords[nftUUID] == nil {
            self.winLossRecords.insert(key: nftUUID, GamingMetadataViews.BasicWinLoss(
                game: RockPaperScissorsGame.name,
                nftID: nftUUID
            ))
        }
    }

    /// Method to update GamingMetadataViews.BasicWinLoss for each NFT based
    /// on Match winner results
    ///
    /// @param: nftUUID: uuid of associated NFT in winLossRecords (nft.id based on updated 
    /// NFTv2 standard)
    /// @param: winner: id of winning NFT or nil if event was a tie
    ///
    access(contract) fun updateWinLossRecord(nftUUID: UInt64, winner: UInt64?) {
        if nftUUID == winner {
            self.winLossRecords[nftUUID]!.addWin()
        } else if nftUUID != winner && winner != nil{
            self.winLossRecords[nftUUID]!.addLoss()
        } else {
            self.winLossRecords[nftUUID]!.addTie()
        }
    }

    /// Update GamingMetadataViews.BasicWinLoss for a certain NFT 
    /// resetting the records for said NFT
    ///
    /// @param: nftUUID: uuid of associated NFT in winLossRecords (nft.id based on updated 
    /// NFTv2 standard)
    ///
    access(contract) fun resetWinLossRecord(nftUUID: UInt64) {
        assert(self.winLossRecords[nftUUID] != nil, message: "NFT does not have an associated record")
        self.winLossRecords[nftUUID]!.reset()
    }

    init() {
        // Initialize variables
        self.name = "RockPaperScissors"
        // TODO: Replace with actual values
        self.info = GamingMetadataViews.GameContractMetadata(
            name: self.name,
            description: "Rock, Paper, Scissors on-chain!",
            icon: MetadataViews.HTTPFile(
                url: "https://static.vecteezy.com/system/resources/previews/000/691/500/large_2x/rock-paper-scissors-vector-icons.jpg"
            ),
            thumbnail: MetadataViews.HTTPFile(
                url: "https://miro.medium.com/max/1400/0*pwDqZoXvHo79MoT7.webp"
            ),
            contractAddress: self.account.address,
            externalURL: MetadataViews.ExternalURL(
                "https://www.cheezewizards.com/"
            )
        )
        self.winLossRecords = {}
        self.completedMatchIDs = []

        // Assign canonical paths
        self.GamePlayerStoragePath = /storage/RockPaperScissorsGamePlayer
        self.GamePlayerPublicPath = /public/RockPaperScissorsGamePlayer
        self.GamePlayerPrivatePath = /private/RockPaperScissorsGamePlayer
        // Assign base paths for later concatenation
        self.MatchStorageBasePathString = "Match"
        self.MatchPrivateBasePathString = "Match"

        // Create a contract GamePlayer to automate second player moves in single player modes
        self.automatedGamePlayer <-create GamePlayer()
        self.dummyNFTID = 0
    }
}
 