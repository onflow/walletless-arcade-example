import { ReactNode } from 'react'

export const Row = (props: { children: ReactNode }) => {
  return (
    <div className="flex w-full flex-row flex-wrap items-center justify-center gap-6 p-1">
      {props.children}
    </div>
  )
}
