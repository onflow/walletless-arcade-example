import type { ReactNode } from 'react'

interface Props {
  children: ReactNode
  textColor?: string
  hoverColor?: string
  bgColor?: string
  onClick?: () => void
}

export default function CustomButton(props: Props) {
  return (
    <button
      className={`bg-${props.bgColor || 'bg-white'} hover:bg-${
        props.hoverColor || 'hover:bg-gray-100'
      } text-${
        props.textColor || 'text-gray-800'
      } rounded border border-gray-400 py-2 px-4 font-semibold shadow`}
      {...props}
    >
      {props.children}
    </button>
  )
}
