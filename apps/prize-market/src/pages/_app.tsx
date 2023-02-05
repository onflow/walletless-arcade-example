import Head from 'next/head'
import { FullScreenLayout, NavBar } from 'ui'
import type { AppProps } from 'next/app'
import '../styles/globals.css'

function MyApp({ Component, pageProps: { session, ...pageProps } }: AppProps) {
  const navProps = {
    session,
  }

  return (
    <>
      <Head>
        <meta name="viewport" content="initial-scale=1.0, width=device-width" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <div className="bg-primary-gray-50">
        <FullScreenLayout nav={<NavBar navProps={navProps} />}>
          <Component {...pageProps} />
        </FullScreenLayout>
      </div>
    </>
  )
}

export default MyApp
