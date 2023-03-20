import type {
  GetServerSidePropsContext,
  InferGetServerSidePropsType,
} from 'next'
import {
  FullScreenLayout,
  FlexContainer,
  Row,
  NavBar,
  CustomButton,
  Modal,
  useFclContext,
  useAppContext,
  FullScreenSpinner,
} from 'shared'
import Image from 'next/image'
import GoogleIcon from '../../public/static/google-icon.png'
import { useSession, getProviders, signIn, signOut } from 'next-auth/react'
import { useRpsGameContext } from '../contexts'
import { getServerSession } from 'next-auth/next'
import { authOptions } from './api/auth/[...nextauth]'

export default function SignIn({
  providers,
}: InferGetServerSidePropsType<typeof getServerSideProps>) {
  const { enabled, fullScreenLoading, fullScreenLoadingMessage } =
    useAppContext()
  const { currentUser, connect, logout: disconnect } = useFclContext()
  const { data: session, status } = useSession()

  const navProps = {
    session,
    currentUser,
    showCurrentUserAddress: !enabled,
    connect,
    disconnect,
    signIn,
    signOut,
  }

  return (
    <>
      <FullScreenLayout nav={<NavBar navProps={navProps} />} theme="green">
        <FlexContainer className="w-full items-center justify-center">
          <div className="m-4 rounded-xl bg-gray-200 p-12">
            <div className="mb-8 w-full items-center justify-center text-center text-xl font-bold">
              Sign In
            </div>
            {Object.values(providers).map(provider => (
              <div className="rounded-md bg-white p-4" key={provider.name}>
                <button
                  className="flex flex-row items-center justify-center"
                  onClick={() => signIn(provider.id)}
                >
                  Sign in with {provider.name}
                  {provider.id === 'google' && (
                    <Image
                      width={100}
                      height={100}
                      alt={`${provider.id} Logo`}
                      src={GoogleIcon.src}
                      className="tile flex h-12 w-12 items-center justify-center"
                    />
                  )}
                </button>
              </div>
            ))}
          </div>
        </FlexContainer>
      </FullScreenLayout>
    </>
  )
}

export async function getServerSideProps(context: GetServerSidePropsContext) {
  const session = await getServerSession(context.req, context.res, authOptions)

  // If the user is already logged in, redirect.
  // Note: Make sure not to redirect to the same page
  // To avoid an infinite loop!
  if (session) {
    return { redirect: { destination: '/' } }
  }

  const providers = await getProviders()

  return {
    props: { providers: providers ?? [] },
  }
}
