import type { NextPage } from 'next'
import Head from 'next/head'
import { FullScreenLayout, NavBar, CustomButton } from 'ui'
import { useSession, signIn, signOut } from 'next-auth/react'
import { useFclContext, useRpsGameContext, useTicketContext } from '../contexts'
import purchaseNft from '../utils/purchase-nft'
import { useRouter } from 'next/router'
import { useEffect } from 'react'
import { GameView } from '../components'

const Home: NextPage = () => {
  const { currentUser, connect, logout: disconnect } = useFclContext()
  const { data: session, status } = useSession()
  const router = useRouter()

  const navProps = {
    session,
    currentUser,
    connect,
    disconnect,
    signIn,
    signOut,
  }

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

  const { ticketAmount } = useTicketContext()

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
    <>
      <Head>
        <title>Flow Game Arcade</title>
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <FullScreenLayout nav={<NavBar navProps={navProps} />} theme="blue">
        <main className="flex w-full flex-col items-center justify-center text-center">
          {!session && (
            <h1 className="text-6xl font-bold">
              Welcome to{' '}
              <a className="text-blue-600" href="https://nextjs.org">
                Flow Game Arcade!
              </a>
            </h1>
          )}
          <div className="mt-3 text-2xl">
            {!session && (
              <div className="mt-3">
                <CustomButton onClick={signIn}>Sign in</CustomButton>
              </div>
            )}

            {session && !isGamePiecePurchased && (
              <div className="mt-3">
                <CustomButton onClick={() => purchaseNft()}>
                  Purchase Game Piece
                </CustomButton>
              </div>
            )}

            {session && isGamePiecePurchased && <GameView />}
          </div>
        </main>
      </FullScreenLayout>
    </>
  )
}

export default Home
