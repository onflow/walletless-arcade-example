import "FungibleToken"
import "FlowToken"

transaction(amount: UFix64, to: Address) {
    prepare(signer: AuthAccount) {
        let recipient = getAccount(to)
        let senderVault = signer.borrow<&FungibleToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow reference to the owner's vault")
        let receiver = recipient.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
            .borrow()
            ?? panic("Could not borrow receiver reference to the recipient's vault")
        let from <- senderVault.withdraw(amount: amount)
        receiver.deposit(from: <- from)
    }
}