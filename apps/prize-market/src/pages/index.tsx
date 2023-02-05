import type { NextPage } from 'next'
import Head from 'next/head'
import Image from 'next/image'
import { Row } from 'ui'
import { FlexContainer, Button, ButtonRef, Card, Footer, LinkCard } from 'ui'

const Home: NextPage = () => {
  const connect = () => {
    console.log('connect')
  }

  return (
    <div className="flex min-h-screen flex-col items-center justify-center py-2">
      <Head>
        <title>Flow Prize Marketplace</title>
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className="flex w-full flex-1 flex-col items-center justify-center px-20 text-center">
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

      <Footer>
        <>
          Powered by{' '}
          <Image src="/vercel.svg" alt="Vercel Logo" width={72} height={16} />
        </>
      </Footer>
    </div>
  )
}

export default Home
