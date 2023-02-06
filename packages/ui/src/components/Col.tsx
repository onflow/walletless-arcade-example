import { ReactNode } from 'react'

const Col = (props: { children: ReactNode }) => {
  return (
    <div className="flex h-auto flex-col items-center justify-center gap-2">
      {props.children}
    </div>
  )
}

export default Col
