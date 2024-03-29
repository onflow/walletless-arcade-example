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
  const [isPreStripeRedirectModalOpen, setIsPreStripeRedirectModalOpen] =
    useState<boolean>(false)

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
    state: { isGamePiecePurchased, setGamePiecePurchased }, isOldSession,
  } = useRpsGameContext()

  const preStripeRedirect = () => {
    if (enabled) purchaseNft()
    else {
      setIsPreStripeRedirectModalOpen(true)
    }
  }

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
                    onClick={() => preStripeRedirect()}
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
            isOldSession === true
          }
          handleClose={() => location.reload()}
          title={'Flow Arcade has been Updated'}
          DialogContent={() => (
            <div>
              {`Since Flow Arcade has been updated, you will need to go through Flow's Walletless Onboarding process. 
                Refresh and start over, The first step is to login using Google Auth.`}
            </div>
          )}
          buttonText={'Reload!'}
          buttonFunc={() => { 
            location.reload();
          }}
        />
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
        <Modal
          isOpen={
            !!session === true &&
            !isGamePiecePurchased &&
            isPreStripeRedirectModalOpen &&
            !enabled &&
            !fullScreenLoading
          }
          handleClose={() => purchaseNft()}
          title={'Before You Purchase'}
          DialogContent={() => (
            <div className="flex flex-col">
              {`You're about to be redirected to Stripe to complete your purchase. Use the Stripe test card "4242-4242-4242-4242" with any Email, Expiration Date, CCV and Location (including Postal Code / Zip Code) to purchase.`}
              <div className="mt-4">
                <button
                  id="copy-button"
                  type="button"
                  className="inline-flex justify-center rounded-md border border-transparent bg-gray-100 px-4 py-2 text-sm font-medium text-black hover:bg-gray-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:ring-offset-2"
                  onClick={async () => {
                    await navigator.clipboard.writeText('4242424242424242')
                    const btnEl = document.getElementById('copy-button')
                    if (btnEl) {
                      btnEl.innerHTML = 'Copied!'
                      setTimeout(() => {
                        btnEl.innerHTML = 'Copy Test Card'
                      }, 2000)
                    }
                  }}
                >
                  Copy Test Card
                </button>
              </div>
            </div>
          )}
          buttonText={'Continue'}
          buttonFunc={() => purchaseNft()}
        />
        {session && isGamePiecePurchased && <GameView />}
      </FullScreenLayout>
    </>
  )
}

export default Home
