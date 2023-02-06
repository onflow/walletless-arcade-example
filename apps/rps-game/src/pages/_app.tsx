import Head from 'next/head'
import { SessionProvider } from 'next-auth/react'
import type { AppProps } from 'next/app'
import {
  FclContext,
  GameAccountContext,
  UserContext,
  RpsGameContext,
  TicketContext,
} from '../contexts'
import '../styles/styles.css'

function MyApp({ Component, pageProps: { session, ...pageProps } }: AppProps) {
  return (
    <>
      <Head>
        <meta name="viewport" content="initial-scale=1.0, width=device-width" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <div className="bg-primary-gray-50">
        <SessionProvider session={session}>
          <FclContext>
            <TicketContext>
              <GameAccountContext>
                <UserContext>
                  <RpsGameContext>
                    <Component {...pageProps} />
                  </RpsGameContext>
                </UserContext>
              </GameAccountContext>
            </TicketContext>
          </FclContext>
        </SessionProvider>
      </div>
    </>
  )
}

export default MyApp
