import MetadataViews from "./utility/MetadataViews.cdc"

/// Metadata views relevant to identifying information about linked accounts
/// designed for use in the standard LinkedAccounts contract
///
pub contract LinkedAccountMetadataViews {

    /// Identifies information that could be used to determine the off-chain
    /// associations of a child account
    ///
    pub struct interface AccountMetadata {
        pub let name: String
        pub let description: String
        pub let creationTimestamp: UFix64
        pub let thumbnail: AnyStruct{MetadataViews.File}
        pub let externalURL: MetadataViews.ExternalURL
    }

    /// Simple metadata struct containing the most basic information about a
    /// linked account
    pub struct AccountInfo : AccountMetadata {
        pub let name: String
        pub let description: String
        pub let creationTimestamp: UFix64
        pub let thumbnail: AnyStruct{MetadataViews.File}
        pub let externalURL: MetadataViews.ExternalURL
        
        init(
            name: String,
            description: String,
            thumbnail: AnyStruct{MetadataViews.File},
            externalURL: MetadataViews.ExternalURL
        ) {
            self.name = name
            self.description = description
            self.creationTimestamp = getCurrentBlock().timestamp
            self.thumbnail = thumbnail
            self.externalURL = externalURL
        }
    }

    /// A struct enabling LinkedAccount.Handler to maintain implementer defined metadata
    /// resolver in conjunction with the default structs above
    ///
    pub struct interface MetadataResolver {
        pub fun getViews(): [Type]
        pub fun resolveView(_ view: Type): AnyStruct{AccountMetadata}?
    }
}
 