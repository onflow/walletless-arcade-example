import type { NextPage } from 'next'
import Head from 'next/head'
import { FullScreenLayout, NavBar, Row, Col, CustomButton } from 'ui'
import { useFclContext, useTicketContext } from '../contexts'
import { FlippyOnHover } from '../components'
import { useEffect } from 'react'

const Home: NextPage = () => {
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
    }
  }

  return (
    <>
      <Head>
        <title>Flow Prize Marketplace</title>
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <FullScreenLayout nav={<NavBar navProps={navProps} />} theme="blue">
        <main className="flex w-full flex-col items-center justify-center text-center">
          <h1 className="m-4 text-4xl font-bold">
            Welcome to{' '}
            <a className="text-blue-300" href="https://nextjs.org">
              Flow Prize Marketplace!
            </a>
          </h1>

          <p className="mb-4 text-2xl text-blue-600">
            Ticket Balance: {totalTicketBalance ? totalTicketBalance : 0}
          </p>

          <Row>
            <Col>
              <FlippyOnHover flipDirection="horizontal" />
              <CustomButton
                textColor="white"
                bgColor="blue-600"
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
                bgColor="blue-600"
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
                bgColor="blue-600"
                hoverColor="blue-800"
                onClick={buyNFT}
              >
                Buy
              </CustomButton>
            </Col>
          </Row>

          <p className="mb-4 text-2xl text-blue-600">
            Owned NFTs:
          </p>

          { ownedPrizes ?
            <Row>
              {ownedPrizes.map(
                (prize) => (
                  <Col>
                    <FlippyOnHover flipDirection="horizontal" />
                  </Col>
                )
              )}
            </Row>
            : <p className="mb-4 text-2xl text-blue-600">
            No owned prizes
            </p>
          }

        </main>
      </FullScreenLayout>
    </>
  )
}

export default Home
 