import { ReactNode } from 'react'

export const Row = (props: { children: ReactNode }) => {
  return (
    <div className="flex h-auto w-full flex-row flex-wrap  items-center justify-center gap-6 rounded-md bg-slate-300 p-3 shadow-inner md:container md:mx-auto">
      {props.children}
    </div>
  )
}
