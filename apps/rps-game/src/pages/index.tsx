import type { NextPage } from 'next'
import Head from 'next/head'
import { FullScreenLayout, Row, NavBar, CustomButton } from 'ui'
import { useSession, signIn, signOut } from 'next-auth/react'
import { useFclContext, useRpsGameContext } from '../contexts'
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
        {!session && (
          <div className="flex w-full">
            <div className="w-full">
              <h1 className="text-center text-5xl font-bold text-blue-600">
                Welcome to Flow Game Arcade!
              </h1>
              <div className="my-10 md:container md:mx-auto lg:my-14">
                <Row>
                  <CustomButton onClick={signIn}>Sign in</CustomButton>
                </Row>
              </div>
            </div>
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
      </FullScreenLayout>
    </>
  )
}

export default Home
