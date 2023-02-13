import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
} from 'react'

import type { ReactNode } from 'react'

interface IAppContext {
  enabled: boolean
  toggleEnabled: () => void
}

export const AppContext = createContext<IAppContext>({} as IAppContext)

export const useAppContext = () => {
  const context = useContext(AppContext)
  if (context === undefined) {
    throw new Error('useAppContext must be used within a AppContextProvider')
  }
  return context
}

export default function AppContextProvider({
  children,
}: {
  children: ReactNode
}) {
  const [enabled, setEnabled] = useState<boolean>(false)

  const toggleEnabled = useCallback(() => {
    setEnabled(enabled => !enabled)
  }, [])

  const providerProps = useMemo(
    () => ({
      enabled,
      toggleEnabled,
    }),
    [enabled, toggleEnabled]
  )

  return (
    <AppContext.Provider
      value={{
        ...providerProps,
      }}
    >
      {children}
    </AppContext.Provider>
  )
}
