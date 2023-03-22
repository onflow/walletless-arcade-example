const ADD_AS_CHILD_MULTISIG = `
#allowAccountLinking

import MetadataViews from 0xMetadataViews
import NonFungibleToken from 0xNonFungibleToken
import LinkedAccountMetadataViews from 0xLinkedAccountMetadataViews
import LinkedAccounts from 0xLinkedAccounts

/// Links thie signing accounts as labeled, with the child's AuthAccount Capability
/// maintained in the parent's LinkedAccounts.Collection
///
transaction(
    linkedAccountName: String,
    linkedAccountDescription: String,
    clientThumbnailURL: String,
    clientExternalURL: String
) {

    let collectionRef: &LinkedAccounts.Collection
    let info: LinkedAccountMetadataViews.AccountInfo
    let authAccountCap: Capability<&AuthAccount>
    let linkedAccountAddress: Address

    prepare(parent: AuthAccount, child: AuthAccount) {
        
        /** --- Configure Collection & get ref --- */
        //
        // Check that Collection is saved in storage
        if parent.type(at: LinkedAccounts.CollectionStoragePath) == nil {
            parent.save(
                <-LinkedAccounts.createEmptyCollection(),
                to: LinkedAccounts.CollectionStoragePath
            )
        }
        // Link the public Capability
        if !parent.getCapability<
                &LinkedAccounts.Collection{LinkedAccounts.CollectionPublic, MetadataViews.ResolverCollection}
            >(LinkedAccounts.CollectionPublicPath).check() {
            parent.unlink(LinkedAccounts.CollectionPublicPath)
            parent.link<&LinkedAccounts.Collection{LinkedAccounts.CollectionPublic, MetadataViews.ResolverCollection}>(
                LinkedAccounts.CollectionPublicPath,
                target: LinkedAccounts.CollectionStoragePath
            )
        }
        // Link the private Capability
        if !parent.getCapability<
                &LinkedAccounts.Collection{LinkedAccounts.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, NonFungibleToken.Provider, MetadataViews.ResolverCollection}
            >(LinkedAccounts.CollectionPrivatePath).check() {
            parent.unlink(LinkedAccounts.CollectionPrivatePath)
            parent.link<
                &LinkedAccounts.Collection{LinkedAccounts.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, NonFungibleToken.Provider, MetadataViews.ResolverCollection}
            >(
                LinkedAccounts.CollectionPrivatePath,
                target: LinkedAccounts.CollectionStoragePath
            )
        }
        // Get Collection reference from signer
        self.collectionRef = parent.borrow<
                &LinkedAccounts.Collection
            >(
                from: LinkedAccounts.CollectionStoragePath
            )!

        /* --- Link the child account's AuthAccount Capability & assign --- */
        //
        // **NOTE:** You'll want to consider adding the AuthAccount Capability path suffix as a transaction arg
        let authAccountPath: PrivatePath = PrivatePath(identifier: "RPSAuthAccountCapability")
            ?? panic("Couldn't create Private Path from identifier: RPSAuthAccountCapability")
        // Get the AuthAccount Capability, linking if necessary
        if !child.getCapability<&AuthAccount>(authAccountPath).check() {
            // Unlink any Capability that may be there
            child.unlink(authAccountPath)
            // Link & assign the AuthAccount Capability
            self.authAccountCap = child.linkAccount(authAccountPath)!
        } else {
            // Assign the AuthAccount Capability
            self.authAccountCap = child.getCapability<&AuthAccount>(authAccountPath)
        }
        self.linkedAccountAddress = self.authAccountCap.borrow()?.address ?? panic("Problem with retrieved AuthAccount Capability")

        /** --- Construct metadata --- */
        //
        // Construct linked account metadata from given arguments
        self.info = LinkedAccountMetadataViews.AccountInfo(
            name: linkedAccountName,
            description: linkedAccountDescription,
            thumbnail: MetadataViews.HTTPFile(url: clientThumbnailURL),
            externalURL: MetadataViews.ExternalURL(clientExternalURL)
        )
    }

    execute {
        // Add child account if it's parent-child accounts aren't already linked
        // *NOTE:*** You may want to add handlerPathSuffix as a transaction arg for greater flexibility as
        // this is where the LinkedAccounts.Handler will be saved in the linked account
        if !self.collectionRef.getLinkedAccountAddresses().contains(self.linkedAccountAddress) {
            // Add the child account
            self.collectionRef.addAsChildAccount(
                linkedAccountCap: self.authAccountCap,
                linkedAccountMetadata: self.info,
                linkedAccountMetadataResolver: nil,
                handlerPathSuffix: "RPSLinkedAccountHandler"
            )
        }
    }

    post {
        self.collectionRef.getLinkedAccountAddresses().contains(self.linkedAccountAddress):
            "Problem linking accounts!"
    }
}
`

export default ADD_AS_CHILD_MULTISIG
