import "AccountCreator"

pub fun main(creatorAddress: Address, pubKey: String): Address? {
    return getAccount(creatorAddress).getCapability<&{AccountCreator.CreatorPublic}>(
            AccountCreator.CreatorPublicPath
        ).borrow()
        ?.getAddressFromPublicKey(publicKey: pubKey)
        ?? panic("Could not borrow reference to CreatorPublic")
}