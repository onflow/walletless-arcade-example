import type { NextPage } from 'next'
import Head from 'next/head'
import { FullScreenLayout, NavBar, Row, Col, CustomButton } from 'ui'
import { useFclContext } from '../contexts'
import { FlippyOnHover } from '../components'

const Home: NextPage = () => {
  const { currentUser, connect, logout: disconnect } = useFclContext()

  const navProps = {
    currentUser,
    connect,
    disconnect,
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

          <p className="mb-4 text-2xl text-blue-600">Ticket Balance: 100</p>

          <Row>
            <Col>
              <FlippyOnHover flipDirection="horizontal" />
              <CustomButton
                textColor="white"
                bgColor="blue-600"
                hoverColor="blue-800"
                onClick={() => console.log('clicked')}
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
                onClick={() => console.log('clicked')}
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
                onClick={() => console.log('clicked')}
              >
                Buy
              </CustomButton>
            </Col>
          </Row>
        </main>
      </FullScreenLayout>
    </>
  )
}

export default Home
