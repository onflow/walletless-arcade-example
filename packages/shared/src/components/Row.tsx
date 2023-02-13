import { ReactNode } from 'react'

export const Row = (props: { children: ReactNode }) => {
  return (
    <div className="flex w-full flex-row items-center justify-center gap-3 p-2 md:container md:mx-auto md:gap-4">
      {props.children}
    </div>
  )
}
