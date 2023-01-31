import {
  useEffect,
  useState,
  useCallback,
  useContext,
  createContext,
} from 'react'
import * as fcl from '@onflow/fcl'
import type { ReactNode } from 'react'
import { useFclContext } from './FclContext'
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
  parentAccountAddress: string | null
  parentAccountWalletConnected: boolean
  getChildAccountAddressFromGameAdmin: (key: string) => Promise<string | null>
}

const initialState: IGameAccountContext = {
  gameAccountAddress: null,
  gameAccountPublicKey: null,
  gameAccountPrivateKey: null,
  parentAccountAddress: null,
  parentAccountWalletConnected: false,
  getChildAccountAddressFromGameAdmin: function (
    key: string
  ): Promise<string | null> {
    throw new Error(`Function not implemented. ${key}`)
  },
}

export const GameAccountContext =
  createContext<IGameAccountContext>(initialState)

export const useGameAccountContext = () => useContext(GameAccountContext)

export default function GameAccountContextProvider({ children }: Props) {
  const { currentUser, executeScript } = useFclContext()
  const [gameAccountAddress, setGameAccountAddress] = useState<null | string>(
    null
  )
  const [gameAccountPublicKey, setGameAccountPublicKey] = useState<
    null | string
  >(null)
  const [gameAccountPrivateKey, setGameAccountPrivateKey] = useState<
    null | string
  >(null)
  const [parentAccountAddress, setParentAccountAddress] = useState<
    null | string
  >(null)
  const [parentAccountWalletConnected, setParentAccountWalletConnected] =
    useState<boolean>(false)

  const getChildAccountAddressFromGameAdmin = useCallback(async (): Promise<
    string | null
  > => {
    const adminAdress = fcl.withPrefix(
      process.env.NEXT_PUBLIC_ADMIN_ADDRESS || ''
    )

    const res: string = await executeScript(
      GET_CHILD_ADDRESS_FROM_PUBLIC_KEY_ON_CREATOR,
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      (arg: any, t: any) => [
        arg(adminAdress, t.Address),
        arg(gameAccountPublicKey, t.String),
      ]
    )

    const session = await getSession()
    await setSession({
      ...session,
      address: res,
    })
    setGameAccountAddress(res)
    return res
  }, [setGameAccountAddress, gameAccountPublicKey, executeScript])

  const getOrCreateGameAccount = useCallback(async () => {
    let gameAccountPublicKey: string
    let gameAccountPrivateKey: string
    let gameAccountAddress: string | null = null
    let parentAccountAddress: string | null = null
    let parentAccountWalletConnected = false

    const session = await getSession()
    if (session) {
      gameAccountPublicKey = session.gameAccountPublicKey
      gameAccountPrivateKey = session.gameAccountPrivateKey
      gameAccountAddress = session.gameAccountAddress
        ? session.gameAccountAddress
        : null
      parentAccountAddress = session.parentAccountAddress
    } else {
      const gameAccountKeys = await generateKeys()
      gameAccountPublicKey = gameAccountKeys.publicKey
      gameAccountPrivateKey = gameAccountKeys.privateKey
      if (currentUser?.addr) {
        // TODO: If Wallet is connected(currentUser?.addr),
        // Child: Grant AuthAccount Capability to ParentAccount
        // Parent: Accept Child AuthAccount Capability, add ChildAccountManager + ChildAccount
        // if successfull
        parentAccountWalletConnected = true
      }

      await setSession({
        gameAccountPrivateKey: gameAccountPrivateKey,
        gameAccountPublicKey: gameAccountPublicKey,
        gameAccountAddress: null,
        parentAccountAddress: parentAccountAddress ?? null,
        parentAccountWalletConnected: parentAccountWalletConnected,
      })
    }

    setGameAccountPublicKey(gameAccountPublicKey)
    setGameAccountPrivateKey(gameAccountPrivateKey)
    setGameAccountAddress(gameAccountAddress)
    if (parentAccountWalletConnected) {
      parentAccountAddress = currentUser?.addr ?? null
      setParentAccountAddress(parentAccountAddress)
      setParentAccountWalletConnected(parentAccountWalletConnected)
    }
  }, [currentUser?.addr])

  useEffect(() => {
    getOrCreateGameAccount()
  }, [getOrCreateGameAccount])

  const value = {
    gameAccountAddress,
    gameAccountPublicKey,
    gameAccountPrivateKey,
    getChildAccountAddressFromGameAdmin,
    getOrCreateGameAccount,
    parentAccountAddress,
    parentAccountWalletConnected,
  }

  return (
    <GameAccountContext.Provider value={value}>
      {children}
    </GameAccountContext.Provider>
  )
}
