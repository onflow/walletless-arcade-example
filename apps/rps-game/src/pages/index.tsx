import type { NextPage } from 'next'
import Head from 'next/head'
import { Button } from '../../components/button-v2'
import { useSession, signIn, signOut } from 'next-auth/react'

const Home: NextPage = () => {
  const { data: session, status } = useSession()

  if (status === 'loading') {
    return (
      <div className="flex flex-grow flex-col items-center justify-center py-2">
        <p>Loading...</p>
      </div>
    )
  }
  return (
    <div className="flex flex-grow flex-col items-center justify-center py-2">
      <Head>
        <title>Flow Game Arcade</title>
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className="flex w-full flex-1 flex-col items-center justify-center px-20 text-center">
        <h1 className="text-6xl font-bold">
          Welcome to{' '}
          <a className="text-blue-600" href="https://nextjs.org">
            Flow Game Arcade!
          </a>
        </h1>

        <p className="mt-3 text-2xl">
          {session ? (
            <>
              Signed in as {session?.user?.email} <br />
              <Button onClick={() => signOut()}>Sign out</Button>
            </>
          ) : (
            <>
              Not signed in <br />
              <Button onClick={() => signIn()}>Sign in</Button>
            </>
          )}
        </p>
      </main>
    </div>
  )
}

export default Home
