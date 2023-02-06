import type { NextPage } from 'next'
import Head from 'next/head'
import { Row, Col, CustomButton } from 'ui'
import { FlippyOnHover } from '../components'

const Home: NextPage = () => {
  const connect = () => {
    console.log('connect')
  }

  return (
    <>
      <Head>
        <title>Flow Prize Marketplace</title>
        <link rel="icon" href="/favicon.ico" />
      </Head>
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
              hoverColor="blue-800"
              bgColor="blue-600"
              onClick={() => console.log('clicked')}
            >
              Buy
            </CustomButton>
          </Col>
          <Col>
            <FlippyOnHover flipDirection="horizontal" />
            <CustomButton
              textColor="white"
              hoverColor="blue-800"
              bgColor="blue-600"
              onClick={() => console.log('clicked')}
            >
              Buy
            </CustomButton>
          </Col>
          <Col>
            <FlippyOnHover flipDirection="horizontal" />
            <CustomButton
              textColor="white"
              hoverColor="blue-800"
              bgColor="blue-600"
              onClick={() => console.log('clicked')}
            >
              Buy
            </CustomButton>
          </Col>
        </Row>
      </main>
    </>
  )
}

export default Home
