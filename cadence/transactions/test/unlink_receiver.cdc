import "NonFungibleToken"
import "MetadataViews"
import "GamePieceNFT"

/// Used to test RockPaperScissors.Match.returnPlayerNFTs() behavior
/// Transaction to unlink NonFungibleToken.Receiver from
/// GamePieceNFT.CollectionPublicPath
///
transaction {

    prepare(acct: AuthAccount) {
        // Return early if the account already has a collection
        if acct.borrow<&GamePieceNFT.Collection>(from: GamePieceNFT.CollectionStoragePath) == nil {
            return
        }

        // Unlink the Receiver Capability
        acct.unlink(GamePieceNFT.CollectionPublicPath)
    }
}