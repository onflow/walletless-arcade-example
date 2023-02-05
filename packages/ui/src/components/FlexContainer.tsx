import { styles } from '../utils'
import type { ReactNode } from 'react'

type FlexContainerProps = {
  children?: ReactNode
  height?: number
  direction?: 'row' | 'col'
  justify?: 'start' | 'center' | 'end' | 'between' | 'around' | 'evenly'
  align?: 'start' | 'center' | 'end' | 'stretch' | 'baseline'
}

export default function FlexContainer({
  children,
  height = 24,
  direction = 'row',
  justify = 'evenly',
  align = 'center',
}: FlexContainerProps) {
  return (
    <div className={styles.container}>
      <div
        className={`flex h-${height} items-center flex-${direction} justify-${justify} align-${align}`}
      >
        {children}
      </div>
    </div>
  )
}
