import Head from 'next/head'
import { FullScreenLayout, NavBar } from 'ui'
import { SessionProvider, signIn, signOut } from 'next-auth/react'
import type { AppProps } from 'next/app'
import {
  FclContext,
  GameAccountContext,
  UserContext,
  RpsGameContext,
  TicketContext,
  useFclContext,
} from '../contexts'
import '../styles/styles.css'

function MyApp({ Component, pageProps: { session, ...pageProps } }: AppProps) {
  const { currentUser, connect, logout: disconnect } = useFclContext()

  const navProps = {
    session,
    currentUser,
    connect,
    disconnect,
    signIn,
    signOut,
  }

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
                    <FullScreenLayout nav={<NavBar navProps={navProps} />}>
                      <Component {...pageProps} />
                    </FullScreenLayout>
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
