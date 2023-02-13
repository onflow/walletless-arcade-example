import type { ReactNode } from 'react'

interface Props {
  children: ReactNode
  textColor?: string
  hoverColor?: string
  bgColor?: string
  onClick?: () => void
}

export default function CustomButton({
  children,
  textColor = 'white',
  bgColor = 'blue-600',
  hoverColor = 'blue-800',
  onClick,
}: Props) {
  return (
    <button
      className={`rounded border border-gray-400 ${bgColor} py-2 px-4 font-semibold text-white shadow hover:bg-blue-800`}
      onClick={onClick}
    >
      {children}
    </button>
  )
}
