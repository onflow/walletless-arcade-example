import { useState } from 'react';
import OnFlowIcon from '../../public/static/flow-icon-bw-green.svg';
import { Hamburger } from "./hamburger"
import { useSession, signIn, signOut } from 'next-auth/react'
import { useFclContext } from "../contexts"
import * as fcl from "@onflow/fcl"

function NavDropDown({ currentUser }: { currentUser: any }) {
  const [isOpen, setIsOpen] = useState(false);
  return (
    <div className="relative">
      <button
        className="border-primary-gray-100 flex items-center whitespace-nowrap stroke-black text-primary-black hover:opacity-75 px-4"
        onClick={() => setIsOpen(!isOpen)}
      >
        <span className="align-middle">Settings</span>
        <svg className="h-5 w-5 ml-1 fill-current text-gray-500 align-middle" viewBox="0 0 20 20" stroke="grey" strokeWidth={0.5} xmlns="http://www.w3.org/2000/svg">
          <path d="M9.293 12.95l.707.707L15.657 8l-1.414-1.414-.707.707L10 10.828 5.757 6.586l-.707-.707L4.343 8z" />
        </svg>
      </button>
      {isOpen && (
        <div className="absolute right-0 w-48 mt-2 origin-top-right rounded-md shadow-lg">
          <div className="px-2 py-2 bg-white rounded-md shadow-xs">
            {
              currentUser?.addr ? 
              <div onClick={() => fcl.unauthenticate()} className="block px-4 py-2 text-sm leading-5 text-gray-700 hover:bg-gray-100 focus:outline-none focus:bg-gray-100">{currentUser?.addr}</div>
              :
              <div onClick={() => fcl.authenticate()} className="block px-4 py-2 text-sm leading-5 text-gray-700 hover:bg-gray-100 focus:outline-none focus:bg-gray-100">Connect Flow Wallet</div>    
            }

          </div>
          <div className="px-2 py-2 bg-white rounded-md shadow-xs">
            <div onClick={() => signOut()} className="block px-4 py-2 text-sm leading-5 text-gray-700 hover:bg-gray-100 focus:outline-none focus:bg-gray-100">Logout</div>
          </div>
        </div>
      )}
    </div>
  );
}

function NavButton({
  href,
  title,
  withBorder,
}: {
  href: string;
  title: string;
  withBorder: boolean;
}) {
  const border = withBorder ? 'border-l' : '';
  return (
    <li className={`${border} border-primary-gray-100`}>
      <a
        className={
          'inline-flex items-center whitespace-nowrap stroke-black text-primary-black hover:opacity-75 px-4'
        }
        href={href}
      >
        <span>{title}</span>
      </a>
    </li>
  );
}

export function Navbar() {
  console.log("OnFlowIcon", OnFlowIcon)
  const { data: session, status } = useSession()
  const { currentUser } = useFclContext()

  const [menuOpen, setMenuOpen] = useState(false);
  return (
    <nav className="z-40 flex min-h-[96px] items-center bg-white p-4 text-primary-gray-400 lg:px-8 border-2 border-primary-gray-100">
      <a
        className="flex items-center font-display text-xl cursor-pointer"
        href="/"
      >
        <img className="mr-4" alt="flow_logo" width="50" height="50" src={OnFlowIcon.src} />
        <header><b>flow</b> games demo</header>
      </a>
      <Hamburger onClick={() => setMenuOpen(true)} />
      {menuOpen && (
        <div className="mt-1 flex flex-1 justify-end lg:hidden">
          <ul className="flex flex-col space-y-4 lg:hidden pb-4">
            <button
              className="flex flex-1 justify-end rounded text-primary-black hover:opacity-75"
              onClick={() => setMenuOpen(false)}
            >
              x
            </button>
            <NavButton title="Connect Flow Wallet" href="/catalog" withBorder={false} />
          </ul>
        </div>
      )}
      <div className="mt-1 flex flex-1 justify-end lg:flex hidden">
        <ul className="flex items-center">
          { session && (
            <>
              <div className="px-4">
                {session?.user?.email}
              </div>
              <div className="h-1/2 border-l border-primary-gray-100"></div>
            </>
          )}
          { session && (
            <>
              <NavDropDown currentUser={currentUser}/> 
              <div className="h-1/2 border-l border-primary-gray-100"></div>
            </>
          )}
          <div className="px-4">
            <a
              className="text-md text-blue-700 hover:text-primary-gray-100 lg:text-base flex items-center space-x-0"
              target="_blank"
              href="https://flow.com" rel="noreferrer"
            >

              Flow.com
              <svg xmlns="http://www.w3.org/2000/svg" fill="white" viewBox="0 0 24 24" strokeWidth={2.5} stroke="black" className="ml-2 mr-4 w-4 h-4">
                <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 19.5l15-15m0 0H8.25m11.25 0v11.25" />
              </svg>

            </a>
          </div>
          <a href="/v">
            {/* <Button>Add NFT Collection </Button> */}
          </a>
        </ul>
      </div>
    </nav>
  );
}