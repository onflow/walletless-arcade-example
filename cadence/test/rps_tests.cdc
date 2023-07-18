import Test

pub var accounts: {String: Test.Account} = {}
pub var blockchain = Test.newEmulatorBlockchain()
pub let fungibleTokenAddress: Address = 0xee82856bf20e2aa6
pub let flowTokenAddress: Address = 0x0ae53cb6e3f42a79

pub let app = "app"
pub let child = "child"
pub let nftFactory = "nftFactory"

pub let dynamicNFT = "DynamicNFT"
pub let gamingMetadataViews = "GamingMetadataViews"
pub let gamePieceNFT = "GamePieceNFT"
pub let ticketToken = "TicketToken"
pub let rockPaperScissorsGame = "RockPaperScissorsGame"
pub let arcadePrize = "ArcadePrize"

pub let capabilityFilter = "CapabilityFilter"

pub let FilterKindAllowList = "allowlist"

pub let gamePieceNFTPublicIdentifier = "GamePieceNFTCollection"
pub let arcadePrizePublicIdentifier = "ArcadePrizeCollection"

pub let pubKey = "af45946342ac9fcc3f909c6f710d3a0c05be903fead0edf77da0bffa572c7a47bfce69218dc54998cdb86f3996fdbfb360be30854f462783188372861549409f"

// --------------- Test cases ---------------

// TODO
pub fun testMintGamePieceNFT() {

}
// TODO
pub fun testCreateGamePlayer() {

}
// TODO
pub fun testGameOnboarding() {

}
// TODO
pub fun testCreateSinglePlayerMatch() {

}
// TODO
pub fun testSubmitSinglePlayerMove() {

}
// TODO
pub fun testSubmitAutomatedPlayerMove() {

}
// TODO
pub fun testCompleteSinglePlayerMatch() {

}
// TODO
pub fun testJoinExistingMultiPlayerMatch() {

}
// TODO
pub fun testCompleteMultiPlayerMatch() {

}
// TODO
pub fun testCheatingMoveFails() {

}
// TODO
pub fun testCheatingResolutionFails() {
    
}

// --------------- Transaction wrapper functions ---------------

pub fun setupFilterAndFactoryManager(_ acct: Test.Account) {
    txExecutor(
        "hybrid_custody/dev_setup/setup_filter_and_factory_manager.cdc",
        [acct],
        [accounts[gamePieceNFT]!.address, gamePieceNFT, accounts[ticketToken]!.address, ticketToken],
        nil,
        nil
    )
}

pub fun transferFlow(amount: UFix64, to: Test.Account) {
    let account = blockchain.serviceAccount()

    let code = loadCode("flow_token/transfer_flow.cdc", "transactions")
    let tx = Test.Transaction(
        code: code,
        authorizers: [account.address],
        signers: [],
        arguments: [to.address, amount]
    )

    // Act
    let result = blockchain.executeTransaction(tx)
    Test.assert(result.status == Test.ResultStatus.succeeded)
}

pub fun walletlessOnboarding(_ acct: Test.Account, fundingAmout: UFix64) {
    txExecutor(
        "onboarding/walletless_onboarding.cdc",
        [acct],
        [pubKey, 0.0, 1, 1, 1, 1],
        nil,
        nil
    )
}

pub fun blockchainNativeOnboarding(
    parent: Test.Account,
    dev: Test.Account,
    fundingAmout: UFix64,
    factoryAddress: Address,
    filterAddress: Address
) {
    txExecutor(
        "onboarding/blockchain_native_onboarding.cdc",
        [parent, dev],
        [pubKey, 0.0, factoryAddress, filterAddress, accounts["GamePieceNFT"]!.address],
        nil,
        nil
    )
}

pub fun addAccountMultiSign (
    parent: Test.Account,
    child: Test.Account,
    childAccountFactoryAddress: Address,
    childAccountFilterAddress: Address
) {
    txExecutor(
        "hybrid_custody/add_account_multi_sign.cdc",
        [parent, child],
        [childAccountFactoryAddress, childAccountFilterAddress],
        nil,
        nil
    )
}

pub fun selfCustodyOnboarding(_ acct: Test.Account) {
    txExecutor(
        "onboarding/self_custody_onboarding.cdc",
        [acct],
        [accounts[gamePieceNFT]!.address],
        nil,
        nil
    )
}

pub fun setupOwnedAccountAndPublish(
    _ acct: Test.Account,
    parent: Address,
    factoryAddress: Address,
    filterAddress: Address
) {
    txExecutor(
        "hybrid_custody/setup_owned_account_and_publish_to_parent.cdc",
        [acct],
        [parent, factoryAddress, filterAddress],
        nil,
        nil
    )
}

pub fun redeemPublishedAccount(_ acct: Test.Account, childAddress: Address) {
    txExecutor(
        "hybrid_custody/redeem_account.cdc",
        [acct],
        [childAddress],
        nil,
        nil
    )
}

pub fun setupNFTCollection(_ acct: Test.Account, collection: String) {
    var success: Bool = false
    switch collection {
        case gamePieceNFT:
            success = txExecutor("game_piece_nft/setup_account.cdc", [acct], [], nil, nil)
        case ticketToken:
            success = txExecutor("ticket_token/setup_account.cdc", [acct], [], nil, nil)
    }
    if !success {
        panic("Failed to setup NFT collection!")
    }
}

pub fun setupTicketTokenVault(_ acct: Test.Account) {
    let success = txExecutor("ticket_token/setup_account.cdc", [acct], [], nil, nil)
    if !success {
        panic("Failed to setup TicketToken Vault!")
    }
}

pub fun mintNFTRandomPublic(_ acct: Test.Account) {
    let filepath: String = "game_piece_nft/mint_nft_random_component_public.cdc"
    txExecutor(filepath, [acct], [accounts[gamePieceNFT]!.address], nil, nil)
}

// ---------------- End Transaction wrapper functions

// ---------------- Begin script wrapper functions

pub fun getFTProviderAllowed(forAddress: Address, identifier: String): Bool {
    let privatePath = PrivatePath(identifier: identifier) ?? panic("Invalid private path identifier provided!")
    return scriptExecutor("test/get_ft_provider_from_factory_allowed.cdc", [forAddress, privatePath])! as! Bool
}

pub fun getParentStatusesForChild(_ child: Test.Account): {Address: Bool} {
    return scriptExecutor("hybrid_custody/get_parents_from_child.cdc", [child.address])! as! {Address: Bool}
}

pub fun isParent(child: Test.Account, parent: Test.Account): Bool {
    return scriptExecutor("hybrid_custody/is_parent.cdc", [child.address, parent.address])! as! Bool
}

pub fun getChildAccountAddresses(parent: Test.Account): [Address] {
    return scriptExecutor("hybrid_custody/get_child_addresses.cdc", [parent.address])! as! [Address]
}

pub fun checkIsRedeemed(child: Test.Account, parent: Test.Account): Bool {
    return scriptExecutor("hybrid_custody/is_redeemed.cdc", [child.address, parent.address])! as! Bool
}

pub fun checkAuthAccountDefaultCap(account: Test.Account): Bool {
    return scriptExecutor("hybrid_custody/check_default_auth_acct_linked_path.cdc", [account.address])! as! Bool
}

pub fun getOwner(child: Test.Account): Address? {
    let res = scriptExecutor("hybrid_custody/get_owner_of_child.cdc", [child.address])
    if res == nil {
        return nil
    }

    return res! as! Address
}

pub fun getPendingOwner(child: Test.Account): Address? {
    let res = scriptExecutor("hybrid_custody/get_pending_owner_of_child.cdc", [child.address])

    return res as! Address?
}

pub fun checkForAddresses(child: Test.Account, parent: Test.Account): Bool {
    let childAddressResult: [Address]? = (scriptExecutor("hybrid_custody/get_child_addresses.cdc", [parent.address])) as! [Address]?
    assert(childAddressResult?.contains(child.address) == true, message: "child address not found")

    let parentAddressResult: [Address]? = (scriptExecutor("hybrid_custody/get_parent_addresses.cdc", [child.address])) as! [Address]?
    assert(parentAddressResult?.contains(parent.address) == true, message: "parent address not found")
    return true
}

pub fun getBalance(_ acct: Test.Account): UFix64 {
    let balance: UFix64? = (scriptExecutor("ticket_token/get_balance.cdc", [acct.address])! as! UFix64)
    return balance!
}

// ---------------- End script wrapper functions

// ---------------- BEGIN General-purpose helper functions

pub fun buildTypeIdentifier(_ acct: Test.Account, _ contractName: String, _ suffix: String): String {
    let addrString = (acct.address as! Address).toString()
    return "A.".concat(addrString.slice(from: 2, upTo: addrString.length)).concat(".").concat(contractName).concat(".").concat(suffix)
}

pub fun getCapabilityFilterPath(): String {
    let filterAcct =  getTestAccount(capabilityFilter)

    return "CapabilityFilter".concat(filterAcct.address.toString())
}

// ---------------- END General-purpose helper functions

pub fun getTestAccount(_ name: String): Test.Account {
    if accounts[name] == nil {
        accounts[name] = blockchain.createAccount()
    }

    return accounts[name]!
}

pub fun loadCode(_ fileName: String, _ baseDirectory: String): String {
    return Test.readFile("../".concat(baseDirectory).concat("/").concat(fileName))
}

pub fun scriptExecutor(_ scriptName: String, _ arguments: [AnyStruct]): AnyStruct? {
    let scriptCode = loadCode(scriptName, "scripts")
    let scriptResult = blockchain.executeScript(scriptCode, arguments)
    var failureMessage = ""
    if let failureError = scriptResult.error {
        failureMessage = "Failed to execute the script because -:  ".concat(failureError.message)
    }

    assert(scriptResult.status == Test.ResultStatus.succeeded, message: failureMessage)
    return scriptResult.returnValue
}

pub fun expectScriptFailure(_ scriptName: String, _ arguments: [AnyStruct]): String {
    let scriptCode = loadCode(scriptName, "scripts")
    let scriptResult = blockchain.executeScript(scriptCode, arguments)

    assert(scriptResult.error != nil, message: "script error was expected but there is no error message")
    return scriptResult.error!.message
}

pub fun txExecutor(_ filePath: String, _ signers: [Test.Account], _ arguments: [AnyStruct], _ expectedError: String?, _ expectedErrorType: ErrorType?): Bool {
    let txCode = loadCode(filePath, "transactions")

    let authorizers: [Address] = []
    for s in signers {
        authorizers.append(s.address)
    }

    let tx = Test.Transaction(
        code: txCode,
        authorizers: authorizers,
        signers: signers,
        arguments: arguments,
    )

    let txResult = blockchain.executeTransaction(tx)
    if let err = txResult.error {
        if let expectedErrorMessage = expectedError {
            let ptr = getErrorMessagePointer(errorType: expectedErrorType!)
            let errMessage = err.message
            let hasEmittedCorrectMessage = contains(errMessage, expectedErrorMessage)
            let failureMessage = "Expecting - "
                .concat(expectedErrorMessage)
                .concat("\n")
                .concat("But received - ")
                .concat(err.message)
            assert(hasEmittedCorrectMessage, message: failureMessage)
            return true
        }
        panic(err.message)
    } else {
        if let expectedErrorMessage = expectedError {
            panic("Expecting error - ".concat(expectedErrorMessage).concat(". While no error triggered"))
        }
    }

    return txResult.status == Test.ResultStatus.succeeded
}

pub fun setup() {
    // main contract account being tested
    let linkedAccount: Test.Account = blockchain.createAccount()
    let hybridCustodyAccount = blockchain.createAccount()
    let capabilityDelegatorAccount = blockchain.createAccount()
    let capabilityFilterAccount = blockchain.createAccount()
    let capabilityFactoryAccount = blockchain.createAccount()

    // factory accounts
    let cpFactory = blockchain.createAccount()
    let providerFactory = blockchain.createAccount()
    let cpAndProviderFactory = blockchain.createAccount()
    let ftProviderFactory = blockchain.createAccount()
    let ftAllFactory = blockchain.createAccount()

    // the account to store a factory manager
    let nftCapFactory = blockchain.createAccount()

    // flow-utils lib contracts
    let arrayUtils = blockchain.createAccount()
    let stringUtils = blockchain.createAccount()
    let addressUtils = blockchain.createAccount()

    // standard contracts
    let nonFungibleToken = blockchain.createAccount()
    let metadataViews = blockchain.createAccount()
    let fungibleTokenMetadataViews = blockchain.createAccount()
    let viewResolver = blockchain.createAccount()
    
    // other contracts used in tests
    let gamingMetadataViews: Test.Account = blockchain.createAccount()
    let dynamicNFT: Test.Account = blockchain.createAccount()
    let gamePieceNFT = blockchain.createAccount()
    let ticketToken = blockchain.createAccount()
    let rockPaperScissorsGame = blockchain.createAccount()
    let arcadePrize = blockchain.createAccount()
    
    // actual test accounts
    let parent = blockchain.createAccount()
    let child1 = blockchain.createAccount()
    let child2 = blockchain.createAccount()

    accounts = {
        "NonFungibleToken": nonFungibleToken,
        "MetadataViews": metadataViews,
        "FungibleTokenMetadataViews": fungibleTokenMetadataViews,
        "ViewResolver": viewResolver,
        "HybridCustody": hybridCustodyAccount,
        "CapabilityDelegator": capabilityDelegatorAccount,
        "CapabilityFilter": capabilityFilterAccount,
        "CapabilityFactory": capabilityFactoryAccount,
        "NFTCollectionPublicFactory": cpFactory,
        "NFTProviderAndCollectionFactory": providerFactory,
        "NFTProviderFactory": cpAndProviderFactory,
        "FTProviderFactory": ftProviderFactory,
        "FTAllFactory": ftAllFactory,
        "ArrayUtils": arrayUtils,
        "StringUtils": stringUtils,
        "AddressUtils": addressUtils,
        "GamingMetadataViews": gamingMetadataViews,
        "DynamicNFT": dynamicNFT,
        "GamePieceNFT": gamePieceNFT,
        "TicketToken": ticketToken,
        "RockPaperScissorsGame": rockPaperScissorsGame,
        "ArcadePrize": arcadePrize,
        "parent": parent,
        "child1": child1,
        "child2": child2,
        "nftCapFactory": nftCapFactory
    }

    blockchain.useConfiguration(Test.Configuration({
        "FungibleToken": fungibleTokenAddress,
        "NonFungibleToken": accounts["NonFungibleToken"]!.address,
        "FlowToken": flowTokenAddress,
        "FungibleTokenMetadataViews": accounts["FungibleTokenMetadataViews"]!.address,
        "MetadataViews": accounts["MetadataViews"]!.address,
        "ViewResolver": accounts["ViewResolver"]!.address,
        "ArrayUtils": accounts["ArrayUtils"]!.address,
        "StringUtils": accounts["StringUtils"]!.address,
        "AddressUtils": accounts["AddressUtils"]!.address,
        "HybridCustody": accounts["HybridCustody"]!.address,
        "CapabilityDelegator": accounts["CapabilityDelegator"]!.address,
        "CapabilityFilter": accounts["CapabilityFilter"]!.address,
        "CapabilityFactory": accounts["CapabilityFactory"]!.address,
        "NFTCollectionPublicFactory": accounts["NFTCollectionPublicFactory"]!.address,
        "NFTProviderAndCollectionFactory": accounts["NFTProviderAndCollectionFactory"]!.address,
        "NFTProviderFactory": accounts["NFTProviderFactory"]!.address,
        "FTProviderFactory": accounts["FTProviderFactory"]!.address,
        "FTAllFactory": accounts["FTAllFactory"]!.address,
        "GamingMetadataViews": accounts["GamingMetadataViews"]!.address,
        "DynamicNFT": accounts["DynamicNFT"]!.address,
        "GamePieceNFT": accounts["GamePieceNFT"]!.address,
        "TicketToken": accounts["TicketToken"]!.address,
        "RockPaperScissorsGame": accounts["RockPaperScissorsGame"]!.address,
        "ArcadePrize": accounts["ArcadePrize"]!.address
    }))

    // deploy standard libs first
    deploy("NonFungibleToken", accounts["NonFungibleToken"]!, "../contracts/utility/NonFungibleToken.cdc")
    deploy("MetadataViews", accounts["MetadataViews"]!, "../contracts/utility/MetadataViews.cdc")
    deploy("FungibleTokenMetadataViews", accounts["FungibleTokenMetadataViews"]!, "../contracts/utility/FungibleTokenMetadataViews.cdc")
    deploy("ViewResolver", accounts["ViewResolver"]!, "../contracts/utility/ViewResolver.cdc")

    // helper libs in the order they are imported
    deploy("ArrayUtils", accounts["ArrayUtils"]!, "../contracts/flow-utils/ArrayUtils.cdc")
    deploy("StringUtils", accounts["StringUtils"]!, "../contracts/flow-utils/StringUtils.cdc")
    deploy("AddressUtils", accounts["AddressUtils"]!, "../contracts/flow-utils/AddressUtils.cdc")

    // helper nft contract so we can actually talk to nfts with tests
    deploy("GamingMetadataViews", accounts["GamingMetadataViews"]!, "../contracts/GamingMetadataViews.cdc")
    deploy("DynamicNFT", accounts["DynamicNFT"]!, "../contracts/DynamicNFT.cdc")
    deploy("GamePieceNFT", accounts["GamePieceNFT"]!, "../contracts/GamePieceNFT.cdc")
    deploy("TicketToken", accounts["TicketToken"]!, "../contracts/TicketToken.cdc")
    deploy("RockPaperScissorsGame", accounts["RockPaperScissorsGame"]!, "../contracts/RockPaperScissorsGame.cdc")
    deploy("ArcadePrize", accounts["ArcadePrize"]!, "../contracts/ArcadePrize.cdc")

    // our main contract is last
    deploy("CapabilityDelegator", accounts["CapabilityDelegator"]!, "../contracts/hybrid-custody/CapabilityDelegator.cdc")
    deploy("CapabilityFilter", accounts["CapabilityFilter"]!, "../contracts/hybrid-custody/CapabilityFilter.cdc")
    deploy("CapabilityFactory", accounts["CapabilityFactory"]!, "../contracts/hybrid-custody/CapabilityFactory.cdc")
    deploy("NFTCollectionPublicFactory", accounts["NFTCollectionPublicFactory"]!, "../contracts/hybrid-custody/factories/NFTCollectionPublicFactory.cdc")
    deploy("NFTProviderAndCollectionFactory", accounts["NFTProviderAndCollectionFactory"]!, "../contracts/hybrid-custody/factories/NFTProviderAndCollectionFactory.cdc")
    deploy("NFTProviderFactory", accounts["NFTProviderFactory"]!, "../contracts/hybrid-custody/factories/NFTProviderFactory.cdc")
    deploy("FTProviderFactory", accounts["FTProviderFactory"]!, "../contracts/hybrid-custody/factories/FTProviderFactory.cdc")
    deploy("FTAllFactory", accounts["FTAllFactory"]!, "../contracts/hybrid-custody/factories/FTAllFactory.cdc")
    deploy("HybridCustody", accounts["HybridCustody"]!, "../contracts/hybrid-custody/HybridCustody.cdc")
}

// BEGIN SECTION: Helper functions. All of the following were taken from
// https://github.com/onflow/Offers/blob/fd380659f0836e5ce401aa99a2975166b2da5cb0/lib/cadence/test/Offers.cdc
// - deploy
// - scriptExecutor
// - txExecutor
// - getErrorMessagePointer

pub fun deploy(_ contractName: String, _ account: Test.Account, _ path: String) {
 let contractCode = Test.readFile(path)
    let err = blockchain.deployContract(
        name: contractName,
        code: contractCode,
        account: account,
        arguments: [],
    )

    if err != nil {
        panic(err!.message)
    }
}

pub enum ErrorType: UInt8 {
    pub case TX_PANIC
    pub case TX_ASSERT
    pub case TX_PRE
}

pub fun getErrorMessagePointer(errorType: ErrorType) : Int {
    switch errorType {
        case ErrorType.TX_PANIC: return 159
        case ErrorType.TX_ASSERT: return 170
        case ErrorType.TX_PRE: return 174
        default: panic("Invalid error type")
    }

    return 0
}

// END SECTION: Helper functions
 

 // Copied functions from flow-utils so we can assert on error conditions
 // https://github.com/green-goo-dao/flow-utils/blob/main/cadence/contracts/StringUtils.cdc
pub fun contains(_ s: String, _ substr: String): Bool {
    if let index =  index(s, substr, 0) {
        return true
    }
    return false
}

 // https://github.com/green-goo-dao/flow-utils/blob/main/cadence/contracts/StringUtils.cdc
pub fun index(_ s : String, _ substr : String, _ startIndex: Int): Int?{
    for i in range(startIndex,s.length-substr.length+1){
        if s[i]==substr[0] && s.slice(from:i, upTo:i+substr.length) == substr{
            return i
        }
    }
    return nil
}

// https://github.com/green-goo-dao/flow-utils/blob/main/cadence/contracts/ArrayUtils.cdc
pub fun rangeFunc(_ start: Int, _ end: Int, _ f : ((Int):Void) ) {
    var current = start
    while current < end{
        f(current)
        current = current + 1
    }
}

pub fun range(_ start: Int, _ end: Int): [Int]{
    var res:[Int] = []
    rangeFunc(start, end, fun (i:Int){
        res.append(i)
    })
    return res
}

pub fun withoutPrefix(_ input: String): String{
    var address=input

    //get rid of 0x
    if address.length>1 && address.utf8[1] == 120 {
        address = address.slice(from: 2, upTo: address.length)
    }

    //ensure even length
    if address.length%2==1{
        address="0".concat(address)
    }
    return address
}
