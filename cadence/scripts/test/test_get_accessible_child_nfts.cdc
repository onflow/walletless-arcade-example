import "HybridCustody"
import "NonFungibleToken"
import "MetadataViews"
import "StringUtils"

/* 
 * TEST SCRIPT
 * This script is a replication of that found in hybrid-custody/get_accessible_child_account_nfts.cdc as it's the best as
 * as can be done without accessing the script's return type in the Cadence testing framework
 */

/// Assertion method to ensure passing test
///
pub fun assertPassing(result: {Address: {UInt64: MetadataViews.Display}}, expectedAddressToIDs: {Address: [UInt64]}) {
  for address in expectedAddressToIDs.keys {
    let expectedIDs: [UInt64] = expectedAddressToIDs[address]!

    for i, id in expectedAddressToIDs[address]! {
      if result[address]![id] == nil {
        panic("Resulting ID does not match expected ID!")
      }
    }
  }
}

pub fun main(addr: Address, expectedAddressToIDs: {Address: [UInt64]}){
  let manager = getAuthAccount(addr).borrow<&HybridCustody.Manager>(from: HybridCustody.ManagerStoragePath) ?? panic ("manager does not exist")

  var typeIdsWithProvider = {} as {Address: [String]} 
  var nftViews = {} as {Address: {UInt64: MetadataViews.Display}} 

  let providerType = Type<Capability<&{NonFungibleToken.Provider}>>()
  let collectionType: Type = Type<@{NonFungibleToken.CollectionPublic}>()

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

      if let cap: Capability = childAcct.getCapability(path: path, type: Type<&{NonFungibleToken.Provider}>()) {
        let providerCap = cap as! Capability<&{NonFungibleToken.Provider}> 

        if !providerCap.check(){
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
                  views.insert(key: id, display)
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
	// Assert instead of return for testing purposes here

  assertPassing(result: nftViews, expectedAddressToIDs: expectedAddressToIDs)
  // return nftViews
}