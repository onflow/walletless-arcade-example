import { SessionProvider } from 'next-auth/react'
import '../../styles/globals.css'
import type { AppProps } from 'next/app'
import { FclContext, GameAccountContext, UserContext, RpsGameContext } from "../../contexts"
import { Navbar } from "../../components/navbar"
import '../../styles/tailwind.css';
import '../../styles/styles.css';

function MyApp({ Component, pageProps: { session, ...pageProps } }: AppProps) {
  return (
    <div className="bg-primary-gray-50">
      <SessionProvider session={session}>
        <FclContext>
          <GameAccountContext>
            <UserContext>
              <RpsGameContext>
                <div className="min-h-screen flex flex-col">
                  <Navbar />
                  <Component {...pageProps} />
                </div>
              </RpsGameContext>
            </UserContext>
          </GameAccountContext>
        </FclContext>
      </SessionProvider>
    </div>
  )
}

export default MyApp
