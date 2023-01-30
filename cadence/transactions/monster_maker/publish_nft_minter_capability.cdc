import MonsterMaker from "../../contracts/MonsterMaker.cdc"

/// This transactions gets a published NFTMinter Capability from the specified provider
/// and saves it in the StoragePath
///
transaction(capabilityName: String, publishFor: Address) {

    prepare(signer: AuthAccount) {
        // Link the NFTMinter Capability if not already linked
        if !signer.getCapability<&MonsterMaker.NFTMinter>(MonsterMaker.MinterPrivatePath).check() {
            signer.unlink(MonsterMaker.MinterPrivatePath)
            signer.link<&MonsterMaker.NFTMinter>(MonsterMaker.MinterPrivatePath, target: MonsterMaker.MinterStoragePath)
        }
        // Get a capability to the minter
        let minterCap = signer.getCapability<&MonsterMaker.NFTMinter>(MonsterMaker.MinterPrivatePath)
        signer.inbox.publish(minterCap, name: capabilityName, recipient: publishFor)
    }
}