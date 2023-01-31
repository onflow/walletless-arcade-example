import MonsterMaker from "../../contracts/MonsterMaker.cdc"

/// This transactions gets a published NFTMinter Capability from the specified provider
/// and saves it in the StoragePath
///
transaction(capabilityName: String, provider: Address) {

    prepare(signer: AuthAccount) {
        // Get the NFTMinter Capability from the provider
        let minterCap: Capability<&MonsterMaker.NFTMinter> = signer.inbox
            .claim<
                &MonsterMaker.NFTMinter
            >(
                capabilityName,
                provider: provider
            ) ?? panic(
                "Could not retrieve NFTMinter Capability named ["
                .concat(capabilityName)
                .concat("] at provider address [")
                .concat(provider.toString())
                .concat("]!")
            )
        // Save the NFTMinter Capability in signer's storage
        signer.save(minterCap, to: MonsterMaker.MinterStoragePath)
    }
}