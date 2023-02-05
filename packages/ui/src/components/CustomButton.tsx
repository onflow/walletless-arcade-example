import type { ReactNode } from 'react'

interface Props {
  textColor: string
  hoverColor: string
  bgColor: string
  children: ReactNode
  onClick: () => void
}

export default function CustomButton(props: Props) {
  return (
    <button
      className={`${props.bgColor || 'bg-white'} ${
        props.hoverColor || 'hover:bg-gray-100'
      } ${
        props.textColor || 'text-gray-800'
      } rounded border border-gray-400 py-2 px-4 font-semibold shadow`}
      {...props}
    >
      {props.children}
    </button>
  )
}
