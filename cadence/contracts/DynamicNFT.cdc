import "MetadataViews"

/// DynamicNFT
/// 
/// In this contract, we've specified a set of interfaces that enable the implementing
/// resources to define resources to which they can be attached & receive resources
/// as Attachments. An Attachment is simply a resource that can be attached to another
/// via the Dynamic interface. Dynamic implies that attributes on the NFT can be altered
/// by entities outside of the NFT's defining contract, and perhaps even with limitations
/// defined by access control that allows another party to alter information that the NFT's
/// owner cannot.
///
/// Why would one want to alter NFT attributes? This sort of behavior is desirable when NFTs
/// are used in games where you want a contract's game logic to govern the data held on
/// an NFT and don't necessarily trust the owner of the resource to not tamper with it in
/// their favor.
/// 
/// Why would you want attachments? They can be very useful for a variety of use cases. 
/// Recall CryptoKitties & KittyItems! Attachments on NFTs introduce a world of composability
/// not available otherwise. We're showcasing that in the first application of DynamicNFT,
/// RockPaperScissorsGame. Any NFT that implements Dynamic can be used in the game which
/// attaches Moves & the ability to recall win/loss records. 
///
/// Note that Attachments will soon be native to Cadence, but this is our best attempt
/// to emulate the specifications in the [Attachments FLIP](https://github.com/onflow/flips/pull/11)
/// with the current language features while also remaining backwards compatible. 
/// If you're reading this when Attachments are live, we recommend leveraging the native
/// feature.
/// 
///
pub contract DynamicNFT {

    /// A view struct that contains information about the types attached to a resource
    ///
    pub struct AttachmentsView {
        /// The id of the associated NFT
        pub let nftID: UInt64
        /// A mapping of the Types attached to the NFT
        pub let attachmentTypes: [Type]
        /// A mapping of the views supported by each type attached to this NFT
        pub let attachmentViews: {Type: [Type]}

        init(nftID: UInt64, attachmentTypes: [Type], attachmentViews: {Type: [Type]}) {
            self.nftID = nftID
            self.attachmentTypes = attachmentTypes
            self.attachmentViews = attachmentViews
        }
    }

    /// Interface that enables the implementing resource to return the views supported by their attachments
    ///
    pub resource interface AttachmentViewResolver {
        /// Mapping of attachments added to the implementing resource
        access(contract) let attachments: @{Type: AnyResource{Attachment, MetadataViews.Resolver}}

        /// Returns the views supported by all of the attachments indexed by the supporting attachment's type
        ///
        /// @return mapping to attachment's Type to view Type
        ///
        pub fun getAttachmentViews(): {Type: [Type]} {

            let viewsByAttachmentType: {Type: [Type]} = {}
            
            // Iterate over the NFT's attachments and get the views they support
            for type in self.attachments.keys {
                if let attachmentRef = &self.attachments[type] as auth &AnyResource{Attachment, MetadataViews.Resolver}? {
                    viewsByAttachmentType.insert(key: type, attachmentRef.getViews())
                }
            }
            
            return viewsByAttachmentType
        }

        /// Given an attachment Type and the view Type, will return the view resolved by the attachment of given Type
        ///
        /// @param attachmentType: The Type of the attachment
        /// @param view: The Type of the desired view to resolve
        ///
        /// @return The resolved view as AnyStruct if it exists and nil otherwise
        ///
        pub fun resolveAttachmentView(attachmentType: Type, view: Type): AnyStruct? {
            if let attachmentRef = &self.attachments[attachmentType] as auth &AnyResource{Attachment, MetadataViews.Resolver}? {
                return attachmentRef.resolveView(view)
            }
            return nil
        }
    }

    /// An interface for a resource defining the Type that an attachment is
    /// designed to be attached to
    ///
    pub resource interface Attachment {
        pub let nftID: UInt64
        pub let attachmentFor: [Type]
    }

    /// An interface defining a resource that can receive and maintain Composite Types implementing 
    /// Attachment and MetadataViews.Resolver
    ///
    pub resource interface Dynamic {
        /// Mapping of attachments added to the implementing resource
        access(contract) let attachments: @{Type: AnyResource{Attachment, MetadataViews.Resolver}}

        /// Adds the attachment to the mapping of attachments, indexed by its type
        ///
        /// @param attachment: AnyResource that is a composite Type of Attachment & MetadataViews.Resolver
        ///
        pub fun addAttachment(_ attachment: @AnyResource{Attachment, MetadataViews.Resolver}) {
            pre {
                !self.hasAttachmentType(attachment.getType()):
                    "NFT already contains attachment of this type!"
            }
        }

        /// Function revealing whether NFT has an attachment of the given Type
        ///
        /// @param type: The type in question
        ///
        /// @return true if NFT has given Type attached and false otherwise
        ///
        pub fun hasAttachmentType(_ type: Type): Bool

        /// Returns a reference to the attachment of the given Type
        ///
        /// @param type: Type of the desired attachment reference
        ///
        /// @return Generic auth reference ready for downcasting
        ///
        pub fun getAttachmentRef(_ type: Type): auth &AnyResource{Attachment, MetadataViews.Resolver}?

        /// Getter method for array of types attached to this NFT
        ///
        /// @return array of attached Types
        ///
        pub fun getAttachmentTypes(): [Type]

        /// Allows for removal of attachments, but should be handled by the contract in which
        /// the implementing resource is defined
        ///
        ///
        /// @param type: The Type of the Attachment that is to be removed
        ///
        /// @return the removed Attachment if one of the given type exists, nil otherwise
        ///
        access(contract) fun removeAttachment(type: Type): @{DynamicNFT.Attachment}?
    }

    /// An interface defining a resource that can receive and maintain Composite Types implementing 
    /// Attachment and MetadataViews.Resolver
    ///
    pub resource interface DynamicPublic {

        /// Function revealing whether NFT has an attachment of the given Type
        ///
        /// @param type: The type in question
        ///
        /// @return true if NFT has given Type attached and false otherwise
        ///
        pub fun hasAttachmentType(_ type: Type): Bool

        /// Returns a reference to the attachment of the given Type
        ///
        /// @param type: Type of the desired attachment reference
        ///
        /// @return Generic auth reference ready for downcasting
        ///
        pub fun getAttachmentRef(_ type: Type): auth &AnyResource{Attachment, MetadataViews.Resolver}?

        /// Getter method for array of types attached to this NFT
        ///
        /// @return array of attached Types
        ///
        pub fun getAttachmentTypes(): [Type]
    }
}
 