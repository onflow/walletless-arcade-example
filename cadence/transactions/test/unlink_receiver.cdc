import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import MetadataViews from "../../contracts/utility/MetadataViews.cdc"
import GamePieceNFT from "../../contracts/GamePieceNFT.cdc"

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