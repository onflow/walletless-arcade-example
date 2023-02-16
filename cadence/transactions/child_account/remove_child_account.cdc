import ChildAccount from "../../contracts/ChildAccount.cdc"

/// This transaction removes access to a child account from the signer's
/// ChildAccountManager. Note that the signer will no longer have access to
/// the removed child account, so care should be taken to ensure any assets
/// in the child account have been first transferred.
///
transaction(childAddress: Address) {

    let managerRef: &ChildAccount.ChildAccountManager
    
    prepare(signer: AuthAccount) {
        // Assign a reference to signer's ChildAccountmanager
        self.managerRef = signer.borrow<
                &ChildAccount.ChildAccountManager
            >(
                from: ChildAccount.ChildAccountManagerStoragePath
            ) ?? panic("Signer does not have a ChildAccountManager configured!")
    }

    execute {
        // Remove child account, revoking any granted Capabilities
        self.managerRef.removeChildAccount(withAddress: childAddress)
    }
}
 