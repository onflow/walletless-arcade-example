import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
} from 'react'

import type { ReactNode } from 'react'

const LOCAL_STORAGE_FIRE_ENABLED = 'LOCAL_STORAGE_FIRE_ENABLED'

interface IAppContext {
  enabled: boolean
  toggleEnabled: () => void
  fullScreenLoading: boolean
  setFullScreenLoading: (loading: boolean) => void
  fullScreenLoadingMessage: string
}

export const AppContext = createContext<IAppContext>({} as IAppContext)

export const useAppContext = () => {
  const context = useContext(AppContext)
  if (context === undefined) {
    throw new Error('useAppContext must be used within a AppContextProvider')
  }
  return context
}

function getFireModeFromLocalStorage() {
  if (typeof window !== 'undefined') {
    const fromStorage =
      window.localStorage.getItem(LOCAL_STORAGE_FIRE_ENABLED) ?? 'false'
    if (typeof JSON.parse(fromStorage) === 'boolean') {
      return JSON.parse(fromStorage)
    }
  }
  return false
}

export default function AppContextProvider({
  children,
}: {
  children: ReactNode
}) {
  const [enabled, setEnabled] = useState<boolean>(getFireModeFromLocalStorage())
  const [fullScreenLoading, setFullScreenLoading] = useState<boolean>(false)
  const [fullScreenLoadingMessage, setFullScreenLoadingMessage] =
    useState<string>('')

  const toggleEnabled = useCallback(() => {
    setEnabled(enabled => {
      if (typeof window !== 'undefined') {
        window.localStorage.setItem(
          LOCAL_STORAGE_FIRE_ENABLED,
          JSON.stringify(!enabled)
        )
      }
      return !enabled
    })
  }, [])

  const providerProps = useMemo(
    () => ({
      enabled,
      toggleEnabled,
      fullScreenLoading,
      setFullScreenLoading,
      fullScreenLoadingMessage,
      setFullScreenLoadingMessage,
    }),
    [
      enabled,
      toggleEnabled,
      fullScreenLoading,
      setFullScreenLoading,
      fullScreenLoadingMessage,
      setFullScreenLoadingMessage,
    ]
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
