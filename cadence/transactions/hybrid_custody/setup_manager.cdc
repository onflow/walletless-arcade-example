import "HybridCustody"
import "CapabilityFilter"

transaction(filterAddress: Address?, filterPath: PublicPath?) {
    prepare(acct: AuthAccount) {
        var filter: Capability<&{CapabilityFilter.Filter}>? = nil
        if filterAddress != nil && filterPath != nil {
            filter = getAccount(filterAddress!).getCapability<&{CapabilityFilter.Filter}>(filterPath!)
        }

        if acct.borrow<&HybridCustody.Manager>(from: HybridCustody.ManagerStoragePath) == nil {
            let m <- HybridCustody.createManager(filter: filter)
            acct.save(<- m, to: HybridCustody.ManagerStoragePath)
        }

        acct.unlink(HybridCustody.ManagerPublicPath)
        acct.unlink(HybridCustody.ManagerPrivatePath)

        acct.link<&HybridCustody.Manager{HybridCustody.ManagerPrivate, HybridCustody.ManagerPublic}>(HybridCustody.ManagerPrivatePath, target: HybridCustody.ManagerStoragePath)
        acct.link<&HybridCustody.Manager{HybridCustody.ManagerPublic}>(HybridCustody.ManagerPublicPath, target: HybridCustody.ManagerStoragePath)
    }
}
 