import type { ReactNode } from 'react'
import FlowLogo from '../components/FlowLogo'

type Props = {
  children?: ReactNode
  nav?: ReactNode
  theme?: 'green' | 'blue'
}

export default function FullScreenLayout({
  nav,
  children,
  theme = 'green',
}: Props) {
  return (
    <div className="flex min-h-screen flex-col">
      <header>{nav}</header>
      <main className="flex flex-1 p-2 sm:p-8 lg:p-10">{children}</main>
      <footer
        className={`flex h-20 w-full items-center justify-center ${
          theme === 'green' ? 'bg-green-100' : 'bg-blue-100'
        } p-2`}
      >
        <a
          className="flex items-center justify-center gap-2"
          href="#"
          target="_blank"
          rel="noopener noreferrer"
        >
          <>
            Powered by Flow <FlowLogo />
          </>
        </a>
      </footer>
    </div>
  )
}
