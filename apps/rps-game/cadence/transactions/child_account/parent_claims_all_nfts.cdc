import GamePieceNFT from "../../contracts/GamePieceNFT.cdc"
import RockPaperScissorsGame from "../../contracts/RockPaperScissorsGame.cdc"

/// This transaction moves all GamePieceNFT.NFTs from the child account to the 
/// parent account. Assuming the parent already has key access to the child
/// account and can sign as the sole authorizer of this transaction, this
/// allows the parent to transfer all NFTs from the child to the parent's
/// collection without requiring the child's authorization.
///
transaction {

    let parentCollectionRef: &GamePieceNFT.Collection
    let childCollectionRef: &GamePieceNFT.Collection
    
    prepare(parent: AuthAccount, child: AuthAccount) {
        pre {
            parent.borrow<&GamePieceNFT.Collection>(from: GamePieceNFT.CollectionStoragePath) != nil :
                "Parent [".concat(parent.address.toString()).concat("] does not have Collection at expected storage path!")
            child.borrow<&GamePieceNFT.Collection>(from: GamePieceNFT.CollectionStoragePath) != nil :
                "Child [".concat(parent.address.toString()).concat("] does not have Collection at expected storage path!")
        }
        // Get a reference to Collections in both accounts
        self.parentCollectionRef = parent
            .borrow<
                &GamePieceNFT.Collection
            >(
                from: GamePieceNFT.CollectionStoragePath
            )!
        self.childCollectionRef = child
            .borrow<
                &GamePieceNFT.Collection
            >(
                from: GamePieceNFT.CollectionStoragePath
            )!
    }

    execute {
        // Withdraw all NFTs from child's Collection into parent's Collection
        for id in self.childCollectionRef.getIDs() {
            self.parentCollectionRef.deposit(token: <-self.childCollectionRef.withdraw(withdrawID: id))
        }
    }
}
