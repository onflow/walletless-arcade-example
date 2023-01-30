import path from "path";
import { 
  emulator, 
  init, 
  getAccountAddress, 
  deployContractByName, 
  sendTransaction, 
  shallPass,
  shallRevert,
  executeScript,
  mintFlow 
} from "@onflow/flow-js-testing";
  import fs from "fs";


// Auxiliary function for deploying the cadence contracts
async function deployContract(param) {
  const [result, error] = await deployContractByName(param);
  if (error != null) {
    console.log(`Error in deployment - ${error}`);
    emulator.stop();
    process.exit(1);
  }
}

const get_child_address_from_creator = fs.readFileSync(path.resolve(__dirname, "./../../../scripts/child_account/get_child_address_from_public_key_on_creator.cdc"), {encoding:'utf8', flag:'r'});


describe("Walletless onboarding", ()=>{

  // Variables for holding the account address
  let serviceAccount;
  let gameAccount;
  let parentAccount;

  // Before each test...
  beforeEach(async () => {
    // We do some scaffolding...

    // Getting the base path of the project
    const basePath = path.resolve(__dirname, "./../../../"); 
		// You can specify different port to parallelize execution of describe blocks
    const port = 8080; 
		// Setting logging flag to true will pipe emulator output to console
    const logging = false;

    await init(basePath);
    await emulator.start({ logging });

    // ...then we deploy the ft and example token contracts using the getAccountAddress function
    // from the flow-js-testing library...

    // Create a service account and deploy contracts to it
    serviceAccount = await getAccountAddress("ServiceAccount")
    await mintFlow(serviceAccount, 10000000.0)

    await deployContract({ to: serviceAccount,    name: "utility/FungibleToken"});
    await deployContract({ to: serviceAccount,    name: "utility/NonFungibleToken"});
    await deployContract({ to: serviceAccount,    name: "utility/MetadataViews"});
    await deployContract({ to: serviceAccount,    name: "utility/FungibleTokenMetadataViews"});
    await deployContract({ to: serviceAccount,    name: "ChildAccount"});
    await deployContract({ to: serviceAccount,    name: "GamingMetadataViews"});

    // Create a game admin account and deploy contracts to it
    gameAccount = await getAccountAddress("gameAccount")
    await mintFlow(gameAccount, 10000000.0)

    await deployContract({ to: gameAccount,   name: "MonsterMaker"});
    await deployContract({ to: gameAccount,   name: "RockPaperScissorsGame"});
    await deployContract({ to: gameAccount,   name: "TicketToken"});
    await deployContract({ to: gameAccount,   name: "ArcadePrize"});

    // Create a parent account that will emulate the wallet-connected account
    parentAccount = await getAccountAddress("ParentAccount");
    await mintFlow(parentAccount, 100.0)

  });

  // After each test we stop the emulator, so it could be restarted
  afterEach(async () => {
    return emulator.stop();
  });

  // First test checks if service account can create a orphan child account 
  test("Game should be able to create and setup a child account", async () => {
    // First step: create a child creator
    await shallPass(
      sendTransaction({
        name: "child_account/setup_child_account_creator",
        args: [],
        signers: [gameAccount]
      })
    );
    // Second step: create a child account
    let pubKey = "eb986126679b4b718208c9d1d92f5b357f46137fe8de2f5bc589b0c5dfc3e8812f256faea8c6719d1ee014e1b08c62d2243af1413dfb6c2cbf36aca229eb5d05"
    await shallPass(
      sendTransaction({
        name: "onboarding/walletless_onboarding_new_flow",
        args: [
                pubKey, 
                10.0, 
                "first_born", 
                "Test child", 
                "someURL", 
                "anotherURL",
                1,
                1,
                1,
                1
              ],
        signers: [gameAccount]
      })
    );
  });


  // Second test checks if a parent can adopt a child account from the minter
  test("Game should be able to associate child to parent", async () => { // parent should accept child!
    // First step: admin create a child creator
    await shallPass(
      sendTransaction({
        name: "child_account/setup_child_account_creator",
        args: [],
        signers: [gameAccount]
      })
    );
    // Second step: create a child account
    let pubKey = "eb986126679b4b718208c9d1d92f5b357f46137fe8de2f5bc589b0c5dfc3e8812f256faea8c6719d1ee014e1b08c62d2243af1413dfb6c2cbf36aca229eb5d05"
    await shallPass(
      sendTransaction({
        name: "onboarding/walletless_onboarding_new_flow",
        args: [
                pubKey, 
                10.0, 
                "first_born", 
                "Test child", 
                "someURL", 
                "anotherURL",
                1,
                1,
                1,
                1
              ],
        signers: [gameAccount]
      })
    );
    // Third step: get the child account address
    const childAccount = await executeScript({
      code: get_child_address_from_creator,
      args: [gameAccount, pubKey]
    });
    // Fourth step: Link parent & child
    await shallPass(
      sendTransaction({
        name: "child_account/add_as_child_multisig",
        args: [],
        signers: [parentAccount, childAccount]
      })
    );
  });
});