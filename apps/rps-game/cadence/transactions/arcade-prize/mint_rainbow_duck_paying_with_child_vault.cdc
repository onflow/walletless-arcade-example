import NonFungibleToken from "../../contracts/utility/NonFungibleToken.cdc"
import MetadataViews from "../../contracts/utility/MetadataViews.cdc"
import ArcadePrize from "../../contracts/ArcadePrize.cdc"
import FungibleToken from "../../contracts/utility/FungibleToken.cdc"
import TicketToken from "../../contracts/TicketToken.cdc"
import ChildAccount from "../../contracts/ChildAccount.cdc"

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

        // Get a reference to the signer's ChildAccountManager from storage
        let managerRef = signer.borrow<
                &ChildAccount.ChildAccountManager
            >(
                from: ChildAccount.ChildAccountManagerStoragePath
            ) ?? panic("Could not borrow reference to ChildAccountManager in signer's account at expected path!")
        // Borrow a reference to the signer's specified child account
        let childAccount = managerRef.getChildAccountRef(address: fundingChildAddress)
            ?? panic("Could not get AuthAccount reference for specified address ".concat(fundingChildAddress.toString()))
        // Get a reference to the child account's TicketToken Vault
        let vaultRef = childAccount.borrow<&TicketToken.Vault>(
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
