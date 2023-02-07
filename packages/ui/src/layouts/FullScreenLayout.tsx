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
      <main className="bg-white-50 flex-1 p-2">
        <div className="mb-20 p-5 md:p-20">{children}</div>
      </main>
      <footer
        className={`flex h-20 w-full items-center justify-center border-t bg-${theme}-100 p-2`}
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
