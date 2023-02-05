import type { NextPage } from 'next'
import Head from 'next/head'
import { FlexContainer, Row, Button, ButtonRef, Card, LinkCard } from 'ui'

const Home: NextPage = () => {
  const connect = () => {
    console.log('connect')
  }

  return (
    <>
      <Head>
        <title>Flow Game Arcade</title>
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <main className="flex w-full flex-col items-center justify-center text-center">
        <h1 className="text-6xl font-bold">
          Welcome to{' '}
          <a className="text-red-600" href="https://nextjs.org">
            Flow Prize Marketplace!
          </a>
        </h1>

        <FlexContainer height={48}>
          <Card title="Shared Card" cta="LFG" href="#" />
          <Card title="Shared Card 2" cta="LFG" href="#" />
          <Card title="Shared Card 2" cta="LFG" href="#" />
        </FlexContainer>
        <Row>
          <Button onClick={connect}>Connect Wallet</Button>
          <Button onClick={connect}>Connect Wallet</Button>
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

        <FlexContainer>
          <Card title="Shared Card" cta="LFG" href="#" />
          <Card title="Shared Card 2" cta="LFG" href="#" />
        </FlexContainer>
        <LinkCard
          src="#"
          title="Link Card"
          text="Instantly deploy your Next.js site to a public URL with Vercel."
        ></LinkCard>
      </main>
    </>
  )
}

export default Home
