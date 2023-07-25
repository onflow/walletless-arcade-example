const GET_ADDRESS_FROM_PUB_KEY = `
import AccountCreator from 0xAccountCreator

pub fun main(creatorAddress: Address, pubKey: String): Address? {

    return getAccount(creatorAddress).getCapability<&{AccountCreator.CreatorPublic}>(
            AccountCreator.CreatorPublicPath
        ).borrow()
        ?.getAddressFromPublicKey(publicKey: pubKey)
        ?? panic("Could not borrow reference to CreatorPublic")
}
`

export default GET_ADDRESS_FROM_PUB_KEY