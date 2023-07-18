import "FungibleToken"
import "NonFungibleToken"
import "MetadataViews"

import "HybridCustody"

import "ArcadePrize"
import "TicketToken"

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

        // Get a reference to the signer's HybridCustody.Manager from storage
        let manager: &HybridCustody.Manager = signer.borrow<&HybridCustody.Manager>(
                from: HybridCustody.ManagerStoragePath
            ) ?? panic("Could not borrow reference to HybridCustody.Manager in signer's account at expected path!")
        // Borrow a reference to the signer's specified child account
        let childAccount: &{HybridCustody.AccountPrivate, HybridCustody.AccountPublic, MetadataViews.Resolver} = manager.borrowAccount(addr: fundingChildAddress)
            ?? panic("Signer does not have access to specified account")

        // Get a reference to the child account's TicketToken Provider
        let providerCap = childAccount.getCapability(
                path: TicketToken.ProviderPrivatePath,
                type: Type<&{FungibleToken.Provider}>()
            ) as! Capability<&{FungibleToken.Provider}>? ?? panic("Could not get a Provider to child account's TicketToken Vault!")
        let providerRef: &{FungibleToken.Provider} = providerCap.borrow()
            ?? panic("Could not borrow a reference to the child account's TicketToken Provider Capability")
        // Withdraw payment in the form of TicketToken
        self.paymentVault <-providerRef.withdraw(amount: ArcadePrize.prizePrices[ArcadePrize.PrizeType.RAINBOWDUCK]!)
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
