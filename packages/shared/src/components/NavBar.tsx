import { useState } from 'react'
import FlowLogo from './FlowLogo'
import ButtonRef from './ButtonRef'
import DevToggle from './DevToggle'
import { useAppContext } from '../contexts'

function NavDropDown({
  session,
  currentUser,
  showCurrentUserAddress = true,
  connect,
  disconnect,
  signIn,
  signOut,
}: {
  session?: any
  currentUser?: any | undefined
  showCurrentUserAddress: boolean
  connect?: any
  disconnect?: any
  signIn?: any
  signOut?: any
}) {
  const [isOpen, setIsOpen] = useState(false)
  return (
    <div className="relative">
      <button
        className="border-primary-gray-100 text-primary-black flex items-center whitespace-nowrap stroke-black px-4 hover:opacity-75"
        onClick={() => setIsOpen(!isOpen)}
      >
        <span className="align-middle">Settings</span>
        <svg
          className="ml-1 h-5 w-5 fill-current align-middle text-gray-500"
          viewBox="0 0 20 20"
          stroke="grey"
          strokeWidth={0.5}
          xmlns="http://www.w3.org/2000/svg"
        >
          <path d="M9.293 12.95l.707.707L15.657 8l-1.414-1.414-.707.707L10 10.828 5.757 6.586l-.707-.707L4.343 8z" />
        </svg>
      </button>
      {isOpen && (
        <div className="absolute right-0 mt-2 w-48 origin-top-right rounded-md shadow-lg">
          <div className="shadow-xs rounded-md bg-white px-2 py-2">
            {currentUser?.addr ? (
              <div
                onClick={disconnect}
                className="block px-4 py-2 text-sm leading-5 text-gray-700 hover:bg-gray-100 focus:bg-gray-100 focus:outline-none"
              >
                Disconnect Wallet
              </div>
            ) : (
              <div
                onClick={connect}
                className="block px-4 py-2 text-sm leading-5 text-gray-700 hover:bg-gray-100 focus:bg-gray-100 focus:outline-none"
              >
                Connect Flow Wallet
              </div>
            )}
          </div>
          {session && (
            <div className="shadow-xs rounded-md bg-white px-2 py-2">
              <div
                onClick={signOut}
                className="block px-4 py-2 text-sm leading-5 text-gray-700 hover:bg-gray-100 focus:bg-gray-100 focus:outline-none"
              >
                Logout
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}

interface NavProps {
  session?: any
  currentUser?: any
  showCurrentUserAddress: boolean
  connect?: any
  disconnect?: any
  signIn?: any
  signOut?: any
}

export default function Navbar({
  navProps: { session, currentUser, showCurrentUserAddress = true, connect, disconnect, signIn, signOut },
}: {
  navProps: NavProps
}) {
  const { enabled, toggleEnabled } = useAppContext()

  return (
    <nav className="text-primary-gray-400 border-primary-gray-100 z-40 flex min-h-[96px] items-center border-2 bg-white p-4 lg:px-8">
      <a
        className="font-display flex cursor-pointer items-center text-xl"
        href="/"
      >
        <FlowLogo className="mr-4" />
        <header>
          <b>Flow</b>Arcade
        </header>
      </a>
      <div className="mt-1 flex flex-1 justify-end lg:flex">
        <ul className="flex items-center">
          {(currentUser?.addr && showCurrentUserAddress) && (
            <>
              <div className="px-4">{currentUser?.addr}</div>
              <div className="border-primary-gray-100 h-1/2 border-l"></div>
            </>
          )}
          {session?.user?.email && (
            <>
              <div className="px-4">{session?.user?.email}</div>
              <div className="border-primary-gray-100 h-1/2 border-l"></div>
            </>
          )}
          {(session || currentUser?.addr) && (
            <>
              <NavDropDown
                session={session}
                currentUser={currentUser}
                showCurrentUserAddress={showCurrentUserAddress}
                connect={connect}
                disconnect={disconnect}
                signIn={signIn}
                signOut={signOut}
              />
              <div className="border-primary-gray-100 h-1/2 border-l"></div>
            </>
          )}
          <div className="px-4">
            <span className="text-primary-gray-400 mr-3">🔥 Mode</span>
            <DevToggle enabled={enabled} toggleEnabled={toggleEnabled} />
            {false && (
              <ButtonRef
                onClick={!currentUser?.addr ? connect : disconnect}
                pill={true}
                variant={'primary'}
                size={'small'}
              >
                {!currentUser?.addr ? 'Connect' : 'Disconnect'} Wallet
              </ButtonRef>
            )}
          </div>
        </ul>
      </div>
    </nav>
  )
}
