import Head from 'next/head'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/router'
import Image from 'next/image'
import {
  FullScreenLayout,
  FlexContainer,
  Row,
  NavBar,
  CustomButton,
  Modal,
  useFclContext,
  useAppContext,
  FullScreenSpinner,
} from 'shared'
import { useSession, signIn, signOut } from 'next-auth/react'
import { useRpsGameContext } from '../contexts'
import purchaseNft from '../utils/purchase-nft'
import { GameView } from '../components'
import MonsterLogo from '../../public/static/monster-logo.png'

import type { NextPage } from 'next'

const Home: NextPage = () => {
  const { enabled, fullScreenLoading, fullScreenLoadingMessage } =
    useAppContext()
  const { currentUser, connect, logout: disconnect } = useFclContext()
  const { data: session, status } = useSession()
  const router = useRouter()

  const [isInitialModalOpen, setIsInitialModalOpen] = useState<boolean>(true)
  const [isPrePurchaseModalOpen, setIsPrepurchaseModalOpen] =
    useState<boolean>(true)

  const navProps = {
    session,
    currentUser,
    showCurrentUserAddress: !enabled,
    connect,
    disconnect,
    signIn,
    signOut,
  }

  const { purchase_success } = router.query

  const {
    state: { isGamePiecePurchased, setGamePiecePurchased },
  } = useRpsGameContext()

  useEffect(() => {
    const fn = async () => {
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
      <FullScreenLayout nav={<NavBar navProps={navProps} />} theme="green">
        <FullScreenSpinner
          display={fullScreenLoading}
          message={fullScreenLoadingMessage}
        />
        {!session && (
          <FlexContainer className="w-full items-center justify-center">
            <div className="w-full">
              <div className="align-center my-10 flex justify-center md:container md:mx-auto lg:my-14">
                <Image src={MonsterLogo} alt="Monster Logo" priority />
              </div>
              <h1 className="text-primary-green text-center text-5xl font-bold">
                Welcome to Monster Arcade!
              </h1>
              <div className="my-10 md:container md:mx-auto lg:my-14">
                <h2 className="text-center text-3xl font-bold text-green-400">
                  Login or sign up to join in the fun.
                </h2>
              </div>
              <div className="my-10 md:container md:mx-auto lg:my-14">
                <Row>
                  <CustomButton onClick={signIn} bgColor="bg-green-600">
                    Login / Sign Up
                  </CustomButton>
                </Row>
              </div>
            </div>
          </FlexContainer>
        )}
        {session && !isGamePiecePurchased && (
          <FlexContainer className="w-full items-center justify-center">
            <div className="w-full">
              <h1 className="text-primary-green text-center text-4xl font-bold">
                You need some monsters to start playing in the arcade.
              </h1>
              <h2 className="text-center text-3xl font-bold text-green-400">
                Lets go shopping for some monsters!
              </h2>
              <div className="my-10 md:container md:mx-auto lg:my-14">
                <Row>
                  <CustomButton
                    onClick={() => purchaseNft()}
                    bgColor="bg-green-600"
                  >
                    Buy Now
                  </CustomButton>
                </Row>
              </div>
            </div>
          </FlexContainer>
        )}
        <Modal
          isOpen={
            !!session === false &&
            isInitialModalOpen &&
            !enabled &&
            !fullScreenLoading
          }
          handleClose={() => setIsInitialModalOpen(false)}
          title={'Welcome to Flow Arcade'}
          DialogContent={() => (
            <div>
              {`This is a demo of Flow's Walletless Onboarding mechanisms. The
                  first step is to login using Google Auth.`}
            </div>
          )}
          buttonText={'Lets start!'}
          buttonFunc={() => setIsInitialModalOpen(false)}
        />
        <Modal
          isOpen={
            !!session === true &&
            !isGamePiecePurchased &&
            isPrePurchaseModalOpen &&
            !enabled &&
            !fullScreenLoading
          }
          handleClose={() => setIsPrepurchaseModalOpen(false)}
          title={"What's Happening?"}
          DialogContent={() => (
            <div>
              {`Now that you're logged in, you're ready to purchase a game piece NFT so you can play the game!
                  Once purchased, the app will create a Flow account in the background, and deposit
                  your game piece to it.`}
            </div>
          )}
          buttonText={'Close'}
          buttonFunc={() => setIsPrepurchaseModalOpen(false)}
        />
        {session && isGamePiecePurchased && <GameView />}
      </FullScreenLayout>
    </>
  )
}

export default Home
