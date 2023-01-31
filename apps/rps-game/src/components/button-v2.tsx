import type { ReactNode } from 'react'

interface Props {
  children: ReactNode
  onClick: () => void
}

export function Button(props: Props) {
  return (
    <button
      className="cursor-pointer rounded-md bg-black py-4 px-6 text-sm text-white hover:bg-gray-100 hover:text-black"
      {...props}
    >
      {props.children}
    </button>
  )
}
