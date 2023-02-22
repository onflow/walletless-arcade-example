import type { NextPage } from 'next'
import Head from 'next/head'
import MonsterLogo from '../../public/static/market-logo.png'
import Image from 'next/image'
import {
  FullScreenLayout,
  NavBar,
  Row,
  CustomButton,
  FlexContainer,
  Col,
  Modal,
  useFclContext,
  useAppContext,
  useTicketContext,
} from 'shared'
import { useEffect, useState } from 'react'
import { FlippyOnHover } from '../components'

const Home: NextPage = () => {
  const [isPurchaseSuccessModalOpen, setIsPurchaseSuccessModalOpen] =
    useState<boolean>(false)
  const [isWalletConnectedModal, setIsWalletConnectedModal] =
    useState<boolean>(false)
  const [isInitialModalOpen, setIsInitialModalOpen] = useState<boolean>(false)
  const { enabled, fullScreenLoading, fullScreenLoadingMessage } =
    useAppContext()
  const { currentUser, connect, logout: disconnect } = useFclContext()
  const {
    getOwnedPrizes,
    childTicketVaultAddress,
    totalTicketBalance,
    purchaseWithTickets,
    getTicketAmount,
  } = useTicketContext()

  const navProps = {
    currentUser,
    showCurrentUserAddress: true,
    connect,
    disconnect,
  }

  useEffect(() => {
    if (currentUser?.addr) {
      getTicketAmount(currentUser.addr, true)
      getOwnedPrizes(currentUser.addr)
    }
  }, [totalTicketBalance, currentUser, getTicketAmount, getOwnedPrizes])

  useEffect(() => {
    if (currentUser?.addr) {
      setIsWalletConnectedModal(true)
    } else {
      setIsInitialModalOpen(true)
    }
  }, [currentUser?.addr])

  const buyNFT = async () => {
    if (currentUser?.addr) {
      const fundingChildAddress = childTicketVaultAddress || currentUser.addr
      await purchaseWithTickets(
        fundingChildAddress,
        process.env.NEXT_PUBLIC_ADMIN_ADDRESS || ''
      )
      getTicketAmount(currentUser.addr, true)
      setIsPurchaseSuccessModalOpen(true)
    }
  }

  return (
    <>
      <Modal
        isOpen={isWalletConnectedModal && !enabled && !fullScreenLoading}
        handleClose={() => null}
        title={'Wallet Connected!'}
        DialogContent={() => (
          <div>
            {`Now that you've connected your wallet, your balance reflects
            the tickets you won in the Monster Arcade. You can redeem them for
            an NFT prize without having to withdraw to your own wallet.`}
          </div>
        )}
        buttonText={'Close'}
        buttonFunc={() => setIsWalletConnectedModal(false)}
      />
      <Modal
        isOpen={isPurchaseSuccessModalOpen && !enabled && !fullScreenLoading}
        handleClose={() => null}
        title={'Purchase Successful!'}
        DialogContent={() => (
          <div>
            {`You used tickets from your linked game account to purchase an NFT
            without needing to withdraw them! The Rainbow Ducky NFT was minted
            to you main account.`}
          </div>
        )}
        buttonText={'View Purchase'}
        buttonFunc={() => {
          setIsPurchaseSuccessModalOpen(false)
          window.location.replace('/wallet')
        }}
      />
      <Head>
        <title>Flow Prize Marketplace</title>
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <FullScreenLayout nav={<NavBar navProps={navProps} />} theme="blue">
        {!currentUser?.addr && (
          <FlexContainer className="w-full items-center justify-center">
            <div className="w-full">
              <div className="align-center my-10 flex justify-center md:container md:mx-auto lg:my-14">
                <Image src={MonsterLogo} alt="Monster Logo" />
              </div>
              <h1 className="text-center text-5xl font-bold text-blue-700">
                Welcome to Monster Mall!
              </h1>
              <div className="my-10 md:container md:mx-auto lg:my-14">
                <h2 className="text-center text-3xl font-bold text-blue-400">
                  Connect your wallet to buy and sell monsters or redeem your
                  game tickets for exciting prizes!
                </h2>
              </div>
              <div className="my-10 md:container md:mx-auto lg:my-14">
                <Row>
                  <CustomButton onClick={connect} bgColor="bg-blue-600">
                    Connect Wallet
                  </CustomButton>
                </Row>
              </div>
            </div>
          </FlexContainer>
        )}
        {currentUser?.addr && (
          <div className="flex w-full flex-wrap">
            <div className="w-full">
              <div className="flex w-full items-center justify-center space-x-4 pt-6 text-2xl text-blue-500">
                <span className="pt-6 text-4xl font-extrabold">
                  🎟 Ticket Balance: {totalTicketBalance || 0}
                </span>
              </div>
            </div>
            <div className="w-full">
              <Row>
                <Col>
                  <FlippyOnHover flipDirection="horizontal" />
                  <CustomButton
                    textColor="white"
                    bgColor="bg-blue-600"
                    hoverColor="blue-800"
                    onClick={buyNFT}
                  >
                    Buy
                  </CustomButton>
                </Col>
                <Col>
                  <FlippyOnHover flipDirection="horizontal" />
                  <CustomButton
                    textColor="white"
                    bgColor="bg-blue-600"
                    hoverColor="blue-800"
                    onClick={buyNFT}
                  >
                    Buy
                  </CustomButton>
                </Col>
                <Col>
                  <FlippyOnHover flipDirection="horizontal" />
                  <CustomButton
                    textColor="white"
                    bgColor="bg-blue-600"
                    hoverColor="blue-800"
                    onClick={buyNFT}
                  >
                    Buy
                  </CustomButton>
                </Col>
              </Row>
            </div>
            <div className="w-full">
              <div className="flex w-full items-center justify-center space-x-4 pt-6 text-blue-500">
                <span className="pt-6 font-extrabold">
                  <CustomButton
                    onClick={() => window.location.replace('/wallet')}
                    bgColor="bg-blue-600"
                  >
                    View Wallet
                  </CustomButton>
                </span>
              </div>
            </div>
          </div>
        )}
      </FullScreenLayout>
    </>
  )
}

export default Home
