transaction {
    prepare(signer: AuthAccount) {
        signer.keys.revoke(keyIndex: 0)
    }
}