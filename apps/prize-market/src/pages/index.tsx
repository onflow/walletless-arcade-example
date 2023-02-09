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
} from 'ui'
import { useFclContext, useTicketContext } from '../contexts'
import { useEffect, useState } from 'react'
import { FlippyOnHover } from '../components'

const Home: NextPage = () => {
  const [ isModalOpen, setIsModalOpen ] = useState<boolean>(false) 
  const { currentUser, connect, logout: disconnect } = useFclContext()
  const {
    ownedPrizes,
    getOwnedPrizes,
    childTicketVaultAddress,
    totalTicketBalance,
    purchaseWithTickets,
    getTicketAmount,
  } = useTicketContext()

  const navProps = {
    currentUser,
    connect,
    disconnect,
  }

  useEffect(() => {
    if (currentUser?.addr) {
      getTicketAmount(currentUser.addr, true)
      getOwnedPrizes(currentUser.addr)
    }
  }, [totalTicketBalance, currentUser, getTicketAmount, getOwnedPrizes])

  const buyNFT = async () => {
    if (currentUser?.addr) {
      const fundingAddress = childTicketVaultAddress || currentUser.addr
      await purchaseWithTickets(
        fundingAddress,
        process.env.NEXT_PUBLIC_ADMIN_ADDRESS || ''
      )
      getTicketAmount(currentUser.addr, true)
      setIsModalOpen(true)
    }
  }

  return (
    <>
      <Modal 
        isOpen={isModalOpen}
        handleClose={() => null}
        handleOpen={() => null}
        dialog={"Purchase Successful! View your purchase."}
        buttonText={"View Purchase"}
        buttonFunc={() => {
          setIsModalOpen(false);
          window.location.replace("/wallet");
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
          </div>
        )}
      </FullScreenLayout>
    </>
  )
}

export default Home
