const SIGN_UP_FOR_MATCH_AND_ESCROW_NFT = `
import NonFungibleToken from 0xNonFungibleToken
import MonsterMaker from 0xMonsterMaker
import RockPaperScissorsGame from 0xRockPaperScissorsGame

/// The signer signs up for the specified Match.id, setting up a GamePlayer resource
/// if need be in the process and escrowing the specified MonsterMaker NFT
///
transaction(matchID: UInt64, escrowNFTID: UInt64) {

    let gamePlayerRef: &RockPaperScissorsGame.GamePlayer
    let receiverCap: Capability<&{NonFungibleToken.Receiver}>
    var nft: @MonsterMaker.NFT

    prepare(signer: AuthAccount) {
        // Check if a GamePlayer already exists, pass this block if it does
        if signer.borrow<&RockPaperScissorsGame.GamePlayer>(from: RockPaperScissorsGame.GamePlayerStoragePath) == nil {
            // Create GamePlayer resource
            let gamePlayer <- RockPaperScissorsGame.createGamePlayer()
            // Save it
            signer.save(<-gamePlayer, to: RockPaperScissorsGame.GamePlayerStoragePath)
        }
        // Make sure the public capability is properly linked
        if !signer.getCapability<&{RockPaperScissorsGame.GamePlayerPublic}>(RockPaperScissorsGame.GamePlayerPublicPath).check() {
            signer.unlink(RockPaperScissorsGame.GamePlayerPublicPath)
            // Link GamePlayerPublic Capability so player can be added to Matches
            signer.link<&{
                RockPaperScissorsGame.GamePlayerPublic
            }>(
                RockPaperScissorsGame.GamePlayerPublicPath,
                target: RockPaperScissorsGame.GamePlayerStoragePath
            )
        }
        // Make sure the private capability is properly linked
        if !signer.getCapability<&{RockPaperScissorsGame.GamePlayerID}>(RockPaperScissorsGame.GamePlayerPrivatePath).check() {
            signer.unlink(RockPaperScissorsGame.GamePlayerPublicPath)
            // Link GamePlayerID Capability
            signer.link<&{
                RockPaperScissorsGame.GamePlayerID
            }>(
                RockPaperScissorsGame.GamePlayerPrivatePath,
                target: RockPaperScissorsGame.GamePlayerStoragePath
            )
        }
        // Get the GamePlayer reference from the signing account's storage
        self.gamePlayerRef = signer
            .borrow<&RockPaperScissorsGame.GamePlayer>(
                from: RockPaperScissorsGame.GamePlayerStoragePath
            )!
        
        // Get the account's Receiver Capability
        self.receiverCap = signer.getCapability<
                &{NonFungibleToken.Receiver}
            >(
                MonsterMaker.CollectionPublicPath
            )
        // Get a reference to the account's Provider
        let providerRef = signer.borrow<
                &{NonFungibleToken.Provider}
            >(
                from: MonsterMaker.CollectionStoragePath
            ) ?? panic("Could not borrow reference to account's Provider")
        // Withdraw the desired NFT
        self.nft <-providerRef.withdraw(withdrawID: escrowNFTID) as! @MonsterMaker.NFT
    }

    execute {
        // Sign up for Match - no guarantee match is playable, but gives access to MatchLobbyActions
        self.gamePlayerRef.signUpForMatch(matchID: matchID)
        // Escrow the nft - this method will fail if the Match cannot be joined
        self.gamePlayerRef.depositNFTToMatchEscrow(nft: <-self.nft, matchID: matchID, receiverCap: self.receiverCap)
    }
}
`

export default SIGN_UP_FOR_MATCH_AND_ESCROW_NFT
