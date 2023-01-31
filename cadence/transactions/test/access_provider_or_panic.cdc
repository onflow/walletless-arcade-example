import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import GamePieceNFT from "../../contracts/GamePieceNFT.cdc"

/// Reverts is the Provider Capability is not configured on the signer's
/// account at the expected PrivatePath
///
transaction {

    prepare(signer: AuthAccount) {
        let providerRef: &{NonFungibleToken.Provider} = signer
            .getCapability<
                &{NonFungibleToken.Provider}
            >(
                GamePieceNFT.ProviderPrivatePath
            ).borrow()
            ?? panic("Could not borrow reference to signer's Provider capability")
    }
}