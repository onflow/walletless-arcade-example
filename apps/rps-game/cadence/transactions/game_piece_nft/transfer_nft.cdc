import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import GamePieceNFT from "../../contracts/GamePieceNFT.cdc"

/// This transaction moves all RockPaperScissorsGame & GamePieceNFT
/// assets from the child account to the parent account
///
transaction(nftID: UInt64, recipient: Address) {

    let providerRef: &{NonFungibleToken.Provider}
    let receivingCollectionPublicRef: &{GamePieceNFT.GamePieceNFTCollectionPublic}
    
    prepare(account: AuthAccount) {

        // Get a reference to the signer's Provider
        self.providerRef = account
            .borrow<
                &GamePieceNFT.Collection
            >(
                from: GamePieceNFT.CollectionStoragePath
            ) ?? panic("Could not borrow reference to signer's Provider!")
        
        // Get a reference to the target's Receiver
        self.receivingCollectionPublicRef = getAccount(recipient)
            .getCapability<
                &{GamePieceNFT.GamePieceNFTCollectionPublic}
            >(GamePieceNFT.CollectionPublicPath)
            .borrow()
            ?? panic("Could not borrow reference to Receiver!")
    }

    execute {
        // Deposit NFT from Provider into Receiver
        self.receivingCollectionPublicRef.deposit(
            token: <-self.providerRef.withdraw(withdrawID: nftID)
        )
    }
}
