import type { ReactNode } from 'react'

type FlexContainerProps = {
  children?: ReactNode
  className?: string
  height?: number
  direction?: 'row' | 'col'
  justify?: 'start' | 'center' | 'end' | 'between' | 'around' | 'evenly'
  align?: 'start' | 'center' | 'end' | 'stretch' | 'baseline'
}

export default function FlexContainer({
  children,
  className,
}: FlexContainerProps) {
  return <div className={`flex ${className}`}>{children}</div>
}
