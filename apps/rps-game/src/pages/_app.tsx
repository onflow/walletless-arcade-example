import Head from 'next/head'
import { SessionProvider } from 'next-auth/react'
import type { AppProps } from 'next/app'
import { FclContext, AppContext, TicketContext } from 'shared'
import { GameAccountContext, UserContext, RpsGameContext } from '../contexts'
import '../styles/styles.css'

import { loadFCLConfig } from '../utils/fcl-setup'

loadFCLConfig()

function MyApp({ Component, pageProps: { session, ...pageProps } }: AppProps) {
  return (
    <>
      <Head>
        <meta name="viewport" content="initial-scale=1.0, width=device-width" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <div className="bg-primary-gray-50">
        <SessionProvider session={session}>
          <AppContext>
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
          </AppContext>
        </SessionProvider>
      </div>
    </>
  )
}

export default MyApp
