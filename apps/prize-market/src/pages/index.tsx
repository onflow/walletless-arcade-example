import type { NextPage } from 'next'
import Head from 'next/head'
import { FlexContainer, Row, Button, ButtonRef, Card, LinkCard } from 'ui'
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
          <a className="text-red-600" href="https://nextjs.org">
            Flow Prize Marketplace!
          </a>
        </h1>

        <Row>
          <FlippyOnHover flipDirection="horizontal" />
          <FlippyOnHover flipDirection="horizontal" />
          <FlippyOnHover flipDirection="horizontal" />
        </Row>
        <p className="mt-3 text-2xl">
          <ButtonRef
            onClick={connect}
            pill={true}
            disabled={false}
            variant={'primary'}
            size={'small'}
          >
            Connect Wallet
          </ButtonRef>
        </p>
      </main>
    </>
  )
}

export default Home
