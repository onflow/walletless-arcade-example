import { ReactNode } from 'react'

export const Row = (props: { children: ReactNode }) => {
  return (
    <div className="flex h-auto w-full flex-row flex-wrap items-center justify-center gap-6 bg-slate-300 p-1">
      {props.children}
    </div>
  )
}
