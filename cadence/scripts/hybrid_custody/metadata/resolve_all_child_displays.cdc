import "HybridCustody"
import "MetadataViews"

pub fun main(parent: Address): {Address: MetadataViews.Display?} {
    let displays: {Address: MetadataViews.Display?} = {}
    
    let m = getAuthAccount(parent).borrow<&HybridCustody.Manager>(from: HybridCustody.ManagerStoragePath)
            ?? panic("manager not found")
    
    let childAddresses = m.getChildAddresses()
    for address in childAddresses {
        let c = m.borrowAccount(addr: address) ?? panic("child not found")
    
        let d = c.resolveView(Type<MetadataViews.Display>()) as! MetadataViews.Display?
        displays.insert(key: c.getAddress(), d)
    }
    return displays
}