import {
  useEffect,
  useState,
  useCallback,
  useContext,
  createContext,
} from 'react'
import * as fcl from '@onflow/fcl'
import type { ReactNode } from 'react'
import { useFclContext } from 'shared'
import { generateKeys } from '../utils/crypto'
import { getSession, setSession } from '../utils/session'
import GET_CHILD_ADDRESS_FROM_PUBLIC_KEY_ON_CREATOR from '../../cadence/scripts/child-account/get-child-address-from-public-key-on-creator'

interface Props {
  children?: ReactNode
}

interface IGameAccountContext {
  gameAccountAddress: string | null
  gameAccountPublicKey: string | null
  gameAccountPrivateKey: string | null
  isLoaded: boolean
  getGameAccountAddressFromGameAdmin: (key: string) => Promise<string | null>
  loadGameAccount: () => Promise<void>
}

const initialState: IGameAccountContext = {
  gameAccountAddress: null,
  gameAccountPublicKey: null,
  gameAccountPrivateKey: null,
  isLoaded: false,
  getGameAccountAddressFromGameAdmin: function (
    key: string
  ): Promise<string | null> {
    throw new Error(`Function not implemented. ${key}`)
  },
  loadGameAccount: function (): Promise<void> {
    throw new Error(`Function not implemented.`)
  },
}

export const GameAccountContext =
  createContext<IGameAccountContext>(initialState)

export const useGameAccountContext = () => useContext(GameAccountContext)

export default function GameAccountContextProvider({ children }: Props) {
  const { currentUser, executeScript } = useFclContext()

  const [isLoaded, setIsLoaded] = useState<boolean>(false)

  const [gameAccountAddress, setGameAccountAddress] = useState<null | string>(
    null
  )
  const [gameAccountPublicKey, setGameAccountPublicKey] = useState<
    null | string
  >(null)
  const [gameAccountPrivateKey, setGameAccountPrivateKey] = useState<
    null | string
  >(null)

  const getGameAccountAddressFromGameAdmin = useCallback(
    async (gameAccountPublicKey: string): Promise<string | null> => {
      const adminAdress = fcl.withPrefix(
        process.env.NEXT_PUBLIC_ADMIN_ADDRESS || ''
      )

      if (adminAdress && gameAccountPublicKey) {
        const res: string = await executeScript(
          GET_CHILD_ADDRESS_FROM_PUBLIC_KEY_ON_CREATOR,
          (arg: any, t: any) => [
            arg(adminAdress, t.Address),
            arg(gameAccountPublicKey, t.String),
          ]
        )

        if (res) {
          const session = await getSession()
          await setSession({
            ...session,
            address: res,
          })
          setGameAccountAddress(res)
        }
        return res
      }
      return null
    },
    [setGameAccountAddress, executeScript]
  )

  const loadGameAccount = useCallback(async () => {
    let gameAccountPublicKey: string
    let gameAccountPrivateKey: string
    let gameAccountAddress: string | null = null
    let parentAccountAddress: string | null = null

    const session = await getSession()
    if (session) {
      gameAccountPublicKey = session.gameAccountPublicKey
      gameAccountPrivateKey = session.gameAccountPrivateKey
      gameAccountAddress = session.gameAccountAddress
        ? session.gameAccountAddress
        : null
      parentAccountAddress = session.parentAccountAddress

      if (!gameAccountAddress) {
        gameAccountAddress = await getGameAccountAddressFromGameAdmin(
          gameAccountPublicKey
        )
        await setSession({
          ...session,
          gameAccountAddress: gameAccountAddress,
        })
      }
    } else {
      const gameAccountKeys = await generateKeys()
      gameAccountPublicKey = gameAccountKeys.publicKey
      gameAccountPrivateKey = gameAccountKeys.privateKey
      gameAccountAddress = await getGameAccountAddressFromGameAdmin(
        gameAccountPublicKey
      )

      await setSession({
        gameAccountPrivateKey: gameAccountPrivateKey,
        gameAccountPublicKey: gameAccountPublicKey,
        gameAccountAddress: gameAccountAddress,
        parentAccountAddress: parentAccountAddress ?? null,
      })
    }

    setGameAccountPublicKey(gameAccountPublicKey)
    setGameAccountPrivateKey(gameAccountPrivateKey)
    setGameAccountAddress(gameAccountAddress)
  }, [getGameAccountAddressFromGameAdmin])

  useEffect(() => {
    if (gameAccountPrivateKey && gameAccountPublicKey) {
      setIsLoaded(true)
    }
  }, [gameAccountAddress, gameAccountPrivateKey, gameAccountPublicKey])

  const value = {
    gameAccountAddress,
    gameAccountPublicKey,
    gameAccountPrivateKey,
    getGameAccountAddressFromGameAdmin,
    loadGameAccount,
    isLoaded,
  }

  return (
    <GameAccountContext.Provider value={value}>
      {children}
    </GameAccountContext.Provider>
  )
}
