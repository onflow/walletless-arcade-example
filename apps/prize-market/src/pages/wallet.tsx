import type { NextPage } from 'next'
import Head from 'next/head'
import Image from 'next/image'
import {
  FullScreenLayout,
  NavBar,
  Row,
  CustomButton,
  FlexContainer,
  Col,
  useFclContext,
  useTicketContext,
} from 'shared'
import { useEffect } from 'react'
import { FlippyOnHover } from '../components'
import MonsterLogo from '../../public/static/market-logo.png'

const Wallet: NextPage = () => {
  const { currentUser, connect, logout: disconnect } = useFclContext()
  const { ownedPrizes, getOwnedPrizes, totalTicketBalance, getTicketAmount } =
    useTicketContext()

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

  if (!currentUser) {
    return (
      <div className="flex flex-grow flex-col items-center justify-center py-2">
        <p>Loading...</p>
      </div>
    )
  }

  return (
    <>
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
          <div className="flex h-24 w-full flex-wrap justify-center">
            <div className="w-full w-1/2">
              <Row>
                <Col>
                  <div className="mb-4 text-2xl font-bold text-blue-600">
                    Owned NFTs
                  </div>
                  {ownedPrizes ? (
                    <Row>
                      {Object.values(ownedPrizes).map(accountOwnedPrizes => accountOwnedPrizes.map((prize: any) => (
                        <Col>
                          <FlippyOnHover 
                            image={prize.thumbnail}
                            cardTitle={prize.name}
                            cardContents={prize.collectionName}
                            cardBackContents={prize.description}
                            flipDirection="horizontal" 
                          />
                        </Col>
                      )))}
                    </Row>
                  ) : (
                    <p className="mb-4 text-2xl text-blue-600">
                      No owned prizes
                    </p>
                  )}
                </Col>
              </Row>
            </div>
          </div>
        )}
      </FullScreenLayout>
    </>
  )
}

export default Wallet
