import Head from 'next/head'
import type { AppProps } from 'next/app'
import { FclContext } from '../contexts'
import '../styles/globals.css'

function MyApp({ Component, pageProps: { ...pageProps } }: AppProps) {
  return (
    <>
      <Head>
        <meta name="viewport" content="initial-scale=1.0, width=device-width" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <FclContext>
        <div className="bg-primary-gray-50">
          <Component {...pageProps} />
        </div>
      </FclContext>
    </>
  )
}

export default MyApp
