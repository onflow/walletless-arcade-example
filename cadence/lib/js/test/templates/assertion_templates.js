import { expect } from "@jest/globals";
import { executeScript } from "@onflow/flow-js-testing";
import { getCollectionIDs } from "./script_templates";

// Asserts whether length of account's collection matches
// the expected collection length
export async function assertCollectionLength(account, expectedCollectionLength) {
    const [collectionIDs, e] = await executeScript(
        "game_piece_nft/get_collection_ids",
        [account]
    );
    expect(e).toBeNull();
    expect(collectionIDs.length).toBe(expectedCollectionLength);
};

// Asserts that total supply of ExampleNFT matches passed expected total supply
export async function assertTotalSupply(expectedTotalSupply) {
    const [actualTotalSupply, e] = await executeScript(
        "get_total_supply"
    );
    expect(e).toBeNull();
    expect(actualTotalSupply).toBe(expectedTotalSupply.toString());
};

// Asserts whether the NFT corresponding to the id is in address's collection
export async function assertNFTInCollection(address, id) {
    const ids = await getCollectionIDs(address);
    expect(ids.includes(id.toString())).toBe(true);
};
