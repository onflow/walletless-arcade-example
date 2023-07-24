import "NonFungibleToken"
import "MetadataViews"
import "ArcadePrize"
import "FungibleToken"
import "TicketToken"

/// Transaction to mint ArcadePrize.NFT to recipient's Collection
///
transaction(minterAddress: Address) {

    let minterRef: &ArcadePrize.Administrator{ArcadePrize.NFTMinterPublic}
    let recipientCollectionRef: &ArcadePrize.Collection{NonFungibleToken.CollectionPublic}
    let paymentVault: @FungibleToken.Vault

    prepare(signer: AuthAccount) {
        // Get a reference to the MinterPublic Capability
        self.minterRef = getAccount(minterAddress)
            .getCapability<
                &ArcadePrize.Administrator{ArcadePrize.NFTMinterPublic}
            >(
                ArcadePrize.MinterPublicPath
            ).borrow()
            ?? panic("Could not get a reference to the NFTMinterPublic Capability at the specified address ".concat(minterAddress.toString()))

        // Setup a Collection if one does not exist at the default path
        if !signer.getCapability<&ArcadePrize.Collection{NonFungibleToken.CollectionPublic}>(ArcadePrize.CollectionPublicPath).check() {
            // create collection & save it to the account
            signer.save(<-ArcadePrize.createEmptyCollection(), to: ArcadePrize.CollectionStoragePath)
        }
        // Make sure public capabilities are linked
        if !signer.getCapability<&ArcadePrize.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, ArcadePrize.ArcadePrizeCollectionPublic, MetadataViews.ResolverCollection}>(
            ArcadePrize.CollectionPublicPath
        ).check() {
            signer.unlink(ArcadePrize.CollectionPublicPath)
            // create a public capability for the collection
            signer.link<&{
                NonFungibleToken.Receiver,
                NonFungibleToken.CollectionPublic,
                ArcadePrize.ArcadePrizeCollectionPublic,
                MetadataViews.ResolverCollection
            }>(
                ArcadePrize.CollectionPublicPath,
                target: ArcadePrize.CollectionStoragePath
            )
        }
        // Make sure private capabilities are linked
        if !signer.getCapability<&ArcadePrize.Collection{NonFungibleToken.Provider}>(
            ArcadePrize.ProviderPrivatePath
        ).check() {
            signer.unlink(ArcadePrize.ProviderPrivatePath)
            // Link the Provider Capability in private storage
            signer.link<&{
                NonFungibleToken.Provider
            }>(
                ArcadePrize.ProviderPrivatePath,
                target: ArcadePrize.CollectionStoragePath
            )
        }

        // Get a reference to the signer's Receiver Capability
        self.recipientCollectionRef = signer
            .getCapability<
                &ArcadePrize.Collection{NonFungibleToken.CollectionPublic}
            >(
                ArcadePrize.CollectionPublicPath
            ).borrow()
            ?? panic("Could not get receiver reference to the NFT Collection")

        // Get a reference to the signer's TicketToken Vault
        let vaultRef = signer.borrow<&TicketToken.Vault>(
                from: TicketToken.VaultStoragePath
            ) ?? panic("Could not borrow a reference to the signer's TicketToken Vault at expected path!")
        // Withdraw payment in the form of TicketToken
        self.paymentVault <-vaultRef.withdraw(amount: ArcadePrize.prizePrices[ArcadePrize.PrizeType.RAINBOWDUCK]!)
    }

    execute {
        // Mint the NFT to the signer's Collection
        self.minterRef.mintNFT(
            recipient: self.recipientCollectionRef,
            prizeType: ArcadePrize.PrizeType.RAINBOWDUCK,
            payment: <-self.paymentVault
        )
    }
}
