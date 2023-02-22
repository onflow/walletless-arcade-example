import * as fcl from '@onflow/fcl'
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react'

import type { ReactNode } from 'react'
import { useAppContext } from './AppContext'

interface IFclContext {
  currentUser: fcl.CurrentUserObject | null | undefined
  connect: () => void
  logout: () => void
  executeTransaction: (
    cadence: string,
    args?: any,
    options?: any
  ) => Promise<string | void>
  executeScript: (cadence: string, args?: any) => Promise<any>
  getTransactionStatusOnSealed: (transactionStatus: string) => Promise<any>
  transaction: {
    id: string | null
    inProgress: boolean
    status: number | null
    errorMessage: string
    events: Array<any> | null
  }
}

export const FclContext = createContext<IFclContext>({} as IFclContext)

export const useFclContext = () => {
  const context = useContext(FclContext)
  if (context === undefined) {
    throw new Error('useFclContext must be used within a FclContextProvider')
  }
  return context
}

export default function FclContextProvider({
  children,
}: {
  children: ReactNode
  network?: string
}) {
  const [currentUser, setCurrentUser] = useState<fcl.CurrentUserObject | null>(
    null
  )
  const [transactionInProgress, setTransactionInProgress] = useState(false)
  const [transactionStatus, setTransactionStatus] = useState<number | null>(
    null
  )
  const [transactionError, setTransactionError] = useState('')
  const [transactionEvents, setTransactionEvents] = useState(null)
  const [txId, setTxId] = useState<string | null>(null)

  const { fullScreenLoading, setFullScreenLoading } = useAppContext()

  useEffect(() => fcl.currentUser.subscribe(setCurrentUser), [])

  const connect = useCallback(() => {
    fcl.authenticate()
  }, [])

  const logout = useCallback(async () => {
    await fcl.unauthenticate()
  }, [])

  const getTransactionStatusOnSealed = useCallback(
    async (transactionId: string) => {
      return new Promise((res, rej) => {
        fcl.tx(transactionId).onceSealed().then(res).catch(rej)
      })
    },
    []
  )

  const executeTransaction = useCallback(
    async (
      cadence: string,
      args: any = () => [],
      options: any = {}
    ): Promise<string | void> => {
      setTransactionInProgress(true)
      setTransactionStatus(-1)
      setTransactionEvents(null)
      setFullScreenLoading(true)

      const transactionId = await fcl
        .mutate({
          cadence,
          args,
          payer: options.payer || fcl.authz,
          proposer: options.proposer || fcl.authz,
          authorizations: options.authorizations || [fcl.authz],
          limit: options.limit || 50,
        })
        .catch((e: Error) => {
          setTransactionInProgress(false)
          setTransactionStatus(500)
          setTransactionError(String(e))
        })

      if (transactionId) {
        setTxId(transactionId)

        await new Promise((pres, prej) => {
          fcl.tx(transactionId).subscribe((res: any) => {
            setTransactionStatus(res.status)

            if (res.status >= 4) {
              setTransactionEvents(res.events || null)
              setTransactionInProgress(false)
              setFullScreenLoading(false)

              pres(transactionId)
            } else if (res.status === 5) {
              prej(transactionId)
            }
          })
        })

        return transactionId
      }
    },
    []
  )

  const executeScript = useCallback(
    async (cadence: string, args: any = () => []) => {
      try {
        return await fcl.query({
          cadence: cadence,
          args,
        })
      } catch (error) {
        console.error(error)
        throw error
      }
    },
    []
  )

  const providerProps = useMemo(
    () => ({
      connect,
      logout,
      currentUser,
      executeTransaction,
      executeScript,
      getTransactionStatusOnSealed,
      transaction: {
        id: txId,
        inProgress: transactionInProgress,
        status: transactionStatus,
        errorMessage: transactionError,
        events: transactionEvents,
      },
    }),
    [
      connect,
      logout,
      txId,
      transactionInProgress,
      transactionStatus,
      transactionError,
      transactionEvents,
      executeTransaction,
      executeScript,
      getTransactionStatusOnSealed,
      currentUser,
    ]
  )

  return (
    <FclContext.Provider
      value={{
        ...providerProps,
      }}
    >
      {children}
    </FclContext.Provider>
  )
}
