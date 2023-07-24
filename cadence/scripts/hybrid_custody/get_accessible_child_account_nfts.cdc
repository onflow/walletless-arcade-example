import "HybridCustody"
import "NonFungibleToken"
import "MetadataViews"


// This script iterates through a parent's child accounts, 
// identifies private paths with an accessible NonFungibleToken.Provider, and returns the corresponding typeIds
pub fun main(addr: Address): AnyStruct {
  let manager = getAuthAccount(addr).borrow<&HybridCustody.Manager>(from: HybridCustody.ManagerStoragePath) ?? panic ("manager does not exist")

  var typeIdsWithProvider = {} as {Address: [String]}

  // Address -> nft UUID -> Display
  var nftViews = {} as {Address: {UInt64: MetadataViews.Display}} 

  
  let providerType = Type<Capability<&{NonFungibleToken.Provider}>>()
  let collectionType: Type = Type<@{NonFungibleToken.CollectionPublic}>()

  // Iterate through child accounts
  for address in manager.getChildAddresses() {
    let acct = getAuthAccount(address)
    let foundTypes: [String] = []
    let views: {UInt64: MetadataViews.Display} = {}
    let childAcct = manager.borrowAccount(addr: address) ?? panic("child account not found")
    // get all private paths
    acct.forEachPrivate(fun (path: PrivatePath, type: Type): Bool {
      // Check which private paths have NFT Provider AND can be borrowed
      if !type.isSubtype(of: providerType){
        return true
      }
      if let cap = childAcct.getCapability(path: path, type: Type<&{NonFungibleToken.Provider}>()) {
        let providerCap = cap as! Capability<&{NonFungibleToken.Provider}> 

        if !providerCap.check(){
          // if this isn't a provider capability, exit the account iteration function for this path
          return true
        }
        foundTypes.append(cap.borrow<&AnyResource>()!.getType().identifier)
      }
      return true
    })
    typeIdsWithProvider[address] = foundTypes

    // iterate storage, check if typeIdsWithProvider contains the typeId, if so, add to views
    acct.forEachStored(fun (path: StoragePath, type: Type): Bool {

      if typeIdsWithProvider[address] == nil {
        return true
      }

      for key in typeIdsWithProvider.keys {
        for idx, value in typeIdsWithProvider[key]! {
          let value = typeIdsWithProvider[key]!

          if value[idx] != type.identifier {
            continue
          } else {
            if type.isInstance(collectionType) {
              continue
            }
            if let collection = acct.borrow<&{NonFungibleToken.CollectionPublic}>(from: path) { 
              // Iterate over IDs & resolve the view
              for id in collection.getIDs() {
                let nft = collection.borrowNFT(id: id)
                if let display = nft.resolveView(Type<MetadataViews.Display>())! as? MetadataViews.Display {
                  views.insert(key: nft.uuid, display)
                }
              }
            }
            continue
          }
        }
      }
      return true
    })
    nftViews[address] = views
  }
  return nftViews
}