import { useState } from 'react'
import FlowLogo from '../components/FlowLogo'
import ButtonRef from './ButtonRef'
import Hamburger from './Hamburger'

function NavDropDown({
  session,
  currentUser,
  connect,
  disconnect,
  signIn,
  signOut,
}: {
  session?: any
  currentUser?: any | undefined
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
                {currentUser?.addr}
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
          <div className="shadow-xs rounded-md bg-white px-2 py-2">
            <div
              onClick={() => signOut()}
              className="block px-4 py-2 text-sm leading-5 text-gray-700 hover:bg-gray-100 focus:bg-gray-100 focus:outline-none"
            >
              Logout
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function NavButton({
  href,
  title,
  withBorder,
}: {
  href: string
  title: string
  withBorder: boolean
}) {
  const border = withBorder ? 'border-l' : ''
  return (
    <li className={`${border} border-primary-gray-100`}>
      <a
        className={
          'text-primary-black inline-flex items-center whitespace-nowrap stroke-black px-4 hover:opacity-75'
        }
        href={href}
      >
        <span>{title}</span>
      </a>
    </li>
  )
}

interface NavProps {
  session?: any
  currentUser?: any
  connect?: any
  disconnect?: any
  signIn?: any
  signOut?: any
}

export default function Navbar({
  navProps: { session, currentUser, connect, disconnect, signIn, signOut },
}: {
  navProps: NavProps
}) {
  const [menuOpen, setMenuOpen] = useState(false)
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
      <Hamburger onClick={() => setMenuOpen(true)} />
      {menuOpen && (
        <div className="mt-1 flex flex-1 justify-end lg:hidden">
          <ul className="flex flex-col space-y-4 pb-4 lg:hidden">
            <button
              className="text-primary-black flex flex-1 justify-end rounded hover:opacity-75"
              onClick={() => setMenuOpen(false)}
            >
              x
            </button>
            <NavButton
              title="Connect Flow Wallet"
              href="#"
              withBorder={false}
            />
          </ul>
        </div>
      )}
      <div className="mt-1 flex hidden flex-1 justify-end lg:flex">
        <ul className="flex items-center">
          {session && (
            <>
              <div className="px-4">{session?.user?.email}</div>
              <div className="border-primary-gray-100 h-1/2 border-l"></div>
            </>
          )}
          {session && currentUser && (
            <>
              <NavDropDown
                session={session}
                currentUser={currentUser}
                connect={connect}
                disconnect={disconnect}
                signIn={signIn}
                signOut={signOut}
              />
              <div className="border-primary-gray-100 h-1/2 border-l"></div>
            </>
          )}
          <div className="px-4">
            <ButtonRef
              onClick={!currentUser?.addr ? connect : disconnect}
              pill={true}
              variant={'primary'}
              size={'small'}
            >
              {!currentUser?.addr ? 'Connect' : 'Disconnect'} Wallet
            </ButtonRef>
          </div>
        </ul>
      </div>
    </nav>
  )
}
