import type { NextPage } from 'next'
import Head from 'next/head'
import { Button } from '../components/button-v2'
import { useSession, signIn, signOut } from 'next-auth/react'
import { useRpsGameContext } from '../contexts'
import purchaseNft from '../utils/purchase-nft'
import { useRouter } from 'next/router'
import { useEffect } from 'react'
import GameView from '../components/game-view'

const Home: NextPage = () => {
  const { data: session, status } = useSession()
  const router = useRouter()

  console.log('router.query', router.query)
  const { purchase_success } = router.query

  const {
    state: {
      gameStatus,
      gameMatchID,
      gamePieceNFTID,
      gameResult,
      isGameInitialized,
      isGameInitializedStateLoading,
      setupNewSinglePlayerMatch,
      submitBothSinglePlayerMoves,
      resolveMatchAndReturnNFTS,
      resetGame,
      gamePlayerID,
      winLossRecord,
      isGamePiecePurchased,
      setGamePiecePurchased,
    },
  } = useRpsGameContext()

  console.log('isGamePiecePurchased', isGamePiecePurchased)

  console.log('gameStatus', gameStatus)

  useEffect(() => {
    const fn = async () => {
      console.log('setGamePiecePurchased', purchase_success)
      await setGamePiecePurchased(purchase_success === 'true')
    }
    fn()
  }, [purchase_success, isGamePiecePurchased, setGamePiecePurchased])

  if (status === 'loading') {
    return (
      <div className="flex flex-grow flex-col items-center justify-center py-2">
        <p>Loading...</p>
      </div>
    )
  }
  return (
    <div className="flex flex-grow flex-col items-center justify-center py-2">
      <Head>
        <title>Flow Game Arcade</title>
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className="flex w-full flex-1 flex-col items-center justify-center px-20 text-center">
        {!session && (
          <h1 className="text-6xl font-bold">
            Welcome to{' '}
            <a className="text-blue-600" href="https://nextjs.org">
              Flow Game Arcade!
            </a>
          </h1>
        )}
        <p className="mt-3 text-2xl">
          {!session && (
            <div className="mt-3">
              <Button onClick={signIn}>Sign in</Button>
            </div>
          )}

          {session && !isGamePiecePurchased && (
            <div className="mt-3">
              <Button onClick={() => purchaseNft()}>Purchase Game Piece</Button>
            </div>
          )}

          {session && isGamePiecePurchased && (
            <div className="mt-3">
              <GameView />
            </div>
          )}
        </p>
      </main>
    </div>
  )
}

export default Home
