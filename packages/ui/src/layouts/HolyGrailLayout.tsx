import type { ReactNode } from 'react'
import { Footer } from '../components'

type Props = {
  children?: ReactNode
  nav?: ReactNode
}

export default function HolyGrailLayout({ nav, children }: Props) {
  console.log('HolyGrailLayout', children, nav)
  return (
    <div className="flex min-h-screen flex-col">
      <header className="bg-red-50 p-2">{nav}</header>

      <div className="flex flex-1 flex-col sm:flex-row">
        <main className="flex-1 bg-indigo-100 p-2">{children}</main>

        <nav className="order-first bg-purple-200 p-2 sm:w-32">Navigation</nav>

        <aside className="bg-yellow-100 p-2 sm:w-32">Right Sidebar</aside>
      </div>

      <footer className="bg-gray-100 p-2">{Footer}</footer>
    </div>
  )
}
