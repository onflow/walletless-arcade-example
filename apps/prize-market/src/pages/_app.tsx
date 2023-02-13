import Head from 'next/head'
import type { AppProps } from 'next/app'
import { AppContext, FclContext, TicketContext } from 'shared'
import '../styles/globals.css'
import { loadFCLConfig } from '../utils/fcl-setup'

loadFCLConfig()

function MyApp({ Component, pageProps: { ...pageProps } }: AppProps) {
  return (
    <>
      <Head>
        <meta name="viewport" content="initial-scale=1.0, width=device-width" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <AppContext>
        <FclContext>
          <TicketContext>
            <div className="bg-primary-gray-50">
              <Component {...pageProps} />
            </div>
          </TicketContext>
        </FclContext>
      </AppContext>
    </>
  )
}

export default MyApp
