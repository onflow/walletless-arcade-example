import "AccountCreator"

pub fun main(publicKey: String, address: Address): Int? {
    return AccountCreator.isKeyActiveOnAccount(publicKey: publicKey, address: address)
}