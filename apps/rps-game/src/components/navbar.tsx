import Image from 'next/image'
import { useState } from 'react'
import OnFlowIcon from '../../public/static/flow-icon-bw-green.svg'
import { Hamburger } from './hamburger'

function NavDropDown() {
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
            <a
              href="/transactions"
              className="block px-4 py-2 text-sm leading-5 text-gray-700 hover:bg-gray-100 focus:bg-gray-100 focus:outline-none"
            >
              Connect Flow Wallet
            </a>
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

export function Navbar() {
  const [menuOpen, setMenuOpen] = useState(false)
  return (
    <nav className="text-primary-gray-400 border-primary-gray-100 z-40 flex min-h-[96px] items-center border-2 bg-white p-4 lg:px-8">
      <a
        className="font-display flex cursor-pointer items-center text-xl"
        href="/"
      >
        <Image
          className="mr-4"
          alt="flow_logo"
          width="50"
          height="50"
          src={OnFlowIcon.src}
        />
        <header>
          <b>flow</b> games demo
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
            <NavButton title="Catalog" href="/catalog" withBorder={false} />
            <NavButton title="Proposals" href="/catalog" withBorder={false} />
            <NavButton title="Tools" href="/tools" withBorder={false} />
            <NavButton
              title="Generate Transaction"
              href="/transactions"
              withBorder={false}
            />
            <NavButton title="View NFTs" href="/nfts" withBorder={false} />
            <NavButton
              title="Cadence Scripts"
              href="https://github.com/dapperlabs/nft-catalog#using-the-catalog-for-marketplaces-and-other-nft-applications"
              withBorder={false}
            />
            <a href="/v">{/* <Button>Add NFT Collection </Button> */}</a>
          </ul>
        </div>
      )}
      <div className="mt-1 flex hidden flex-1 justify-end lg:flex">
        <ul className="flex items-center">
          <NavDropDown />
          <div className="border-primary-gray-100 h-1/2 border-l"></div>
          <div className="px-4">
            <a
              className="text-md hover:text-primary-gray-100 flex items-center space-x-0 text-blue-700 lg:text-base"
              target="_blank"
              href="https://flow.com"
              rel="noreferrer"
            >
              Flow.com
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="white"
                viewBox="0 0 24 24"
                strokeWidth={2.5}
                stroke="black"
                className="ml-2 mr-4 h-4 w-4"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M4.5 19.5l15-15m0 0H8.25m11.25 0v11.25"
                />
              </svg>
            </a>
          </div>
          <a href="/v">{/* <Button>Add NFT Collection </Button> */}</a>
        </ul>
      </div>
    </nav>
  )
}
