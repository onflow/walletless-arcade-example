const IS_GAME_PIECE_NFT_COLLECTION_CONFIGURED = `
import NonFungibleToken from 0xNonFungibleToken
import GamePieceNFT from 0xGamePieceNFT

/// Script to check if GamePieceNFTCollectionPublic is configured at
/// a given address
///
pub fun main(address: Address): Bool {
    return getAccount(address).getCapability<&{
        GamePieceNFT.GamePieceNFTCollectionPublic
        }>(
            GamePieceNFT.CollectionPublicPath
        ).check()
}
`;

export default IS_GAME_PIECE_NFT_COLLECTION_CONFIGURED;
