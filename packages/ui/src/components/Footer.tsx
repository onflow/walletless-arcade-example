import { styles } from '../utils'
import type { ReactNode } from 'react'

type FooterProps = {
  children?: ReactNode
}

export default function Footer({ children }: FooterProps) {
  return (
    <footer className="flex h-24 w-full items-center justify-center border-t">
      <a
        className="flex items-center justify-center gap-2"
        href="#"
        target="_blank"
        rel="noopener noreferrer"
      >
        {children}
      </a>
    </footer>
  )
}
