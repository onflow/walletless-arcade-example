import { SessionProvider } from 'next-auth/react'
import '../../styles/globals.css'
import type { AppProps } from 'next/app'
import { FclContext, GameAccountContext, UserContext, RpsGameContext } from "../../contexts"

function MyApp({ Component, pageProps: { session, ...pageProps } }: AppProps) {
  return (
    <SessionProvider session={session}>
      <FclContext>
        <GameAccountContext>
          <UserContext>
            <RpsGameContext>
              <Component {...pageProps} />
            </RpsGameContext>
          </UserContext>
        </GameAccountContext>
      </FclContext>
    </SessionProvider>
  )
}

export default MyApp
