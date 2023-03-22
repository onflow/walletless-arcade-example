const MINT_RAINBOW_DUCK_PAYING_WITH_CHILD_VAULT = `
import NonFungibleToken from 0xNonFungibleToken
import MetadataViews from 0xMetadataViews
import ArcadePrize from 0xArcadePrize
import FungibleToken from 0xFungibleToken
import TicketToken from 0xTicketToken
import LinkedAccounts from 0xLinkedAccounts

/// Transaction to mint ArcadePrize.NFT to recipient's Collection, paying
/// with the TicketToken.Vault in the signer's child account
///
transaction(fundingChildAddress: Address, minterAddress: Address) {

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
            signer.link<
                &ArcadePrize.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, ArcadePrize.ArcadePrizeCollectionPublic, MetadataViews.ResolverCollection}
            >(
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
            signer.link<
                &ArcadePrize.Collection{NonFungibleToken.Provider}
            >(
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

        // Get a reference to the signer's LinkedAccounts.Collection from storage
        let collectionRef: &LinkedAccounts.Collection = signer.borrow<&LinkedAccounts.Collection>(
                from: LinkedAccounts.CollectionStoragePath
            ) ?? panic("Could not borrow reference to LinkedAccounts.Collection in signer's account at expected path!")
        // Borrow a reference to the signer's specified child account
        let childAccount: &AuthAccount = collectionRef.getChildAccountRef(address: fundingChildAddress)
            ?? panic("Signer does not have access to specified account")
        // Get a reference to the child account's TicketToken Vault
        let vaultRef: &TicketToken.Vault = childAccount.borrow<&TicketToken.Vault>(
                from: TicketToken.VaultStoragePath
            ) ?? panic("Could not borrow a reference to the child account's TicketToken Vault at expected path!")
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
`

export default MINT_RAINBOW_DUCK_PAYING_WITH_CHILD_VAULT
