import {
  createContext,
  useContext,
  useCallback,
  useEffect,
  useState,
} from 'react'
import * as fcl from '@onflow/fcl'
import { useFclContext } from 'shared'
import type { ReactNode } from 'react'
import { useGameAccountContext } from './GameAccountContext'
import { userAuthorizationFunction } from '../utils/authz-functions'
import IS_CHILD_ACCOUNT_OF from '../../cadence/scripts/linked-accounts/is_child_account_of'
import ADD_AS_CHILD_MULTISIG from '../../cadence/transactions/linked-accounts/add-as-child-multisig'
import IS_GAME_PIECE_NFT_COLLECTION_CONFIGURED from '../../cadence/scripts/gamepiece-nft/is-collection-configured'

interface Props {
  children?: ReactNode
}

interface IUserContext {
  isAccountInitialized: boolean
  isAccountInitStateLoading: boolean
}

export const UserContext = createContext<IUserContext>({
  isAccountInitialized: false,
  isAccountInitStateLoading: false,
})

export const useUserContext = () => useContext(UserContext)

export default function UserContextProvider({ children }: Props) {
  const [isAccountInitStateLoading, setIsAccountInitStateLoading] =
    useState(false)
  const [isAccountInitialized, setIsAccountInitialized] = useState(false)
  const [
    isUserAccountConnectedToGameAccount,
    setIsUserAccountConnectedToGameAccount,
  ] = useState(false)
  const { currentUser, executeScript, executeTransaction } = useFclContext()

  const { gameAccountPublicKey, gameAccountAddress, gameAccountPrivateKey } =
    useGameAccountContext()

  const checkIsUserAccountInitialized = useCallback(async () => {
    if (currentUser?.addr && gameAccountPublicKey) {
      setIsAccountInitStateLoading(true)
      const isUserInitializedForRps: boolean = await executeScript(
        IS_GAME_PIECE_NFT_COLLECTION_CONFIGURED,
        (arg: any, t: any) => [arg(currentUser.addr, t.Address)]
      )
      setIsAccountInitialized(isUserInitializedForRps)

      return isUserInitializedForRps
    }
    return false
  }, [currentUser?.addr, executeScript, gameAccountPublicKey])

  const checkIsUserAccountConnectedToChildAccount = useCallback(async () => {
    if (currentUser?.addr && gameAccountAddress) {
      // TODO: Also check for child account linked properly to parent account
      try {
        const isUserAccountConnectedToChildAccount: boolean =
          await executeScript(IS_CHILD_ACCOUNT_OF, (arg: any, t: any) => [
            arg(currentUser?.addr, t.Address),
            arg(gameAccountAddress, t.Address),
          ])
        setIsUserAccountConnectedToGameAccount(
          isUserAccountConnectedToChildAccount
        )

        return isUserAccountConnectedToChildAccount
      } catch (e) {
        return false
      }
    }
  }, [currentUser?.addr, executeScript, gameAccountAddress])

  const connectUserAccountToChildAccount = useCallback(async () => {
    if (gameAccountPrivateKey && gameAccountAddress) {
      const txid = await executeTransaction(
        ADD_AS_CHILD_MULTISIG,
        (arg: any, t: any) => [
          arg('RPS Proxy Account', t.String),
          arg('Proxy Account for Flow RPS', t.String),
          arg('flow-games.com/icon.png', t.String),
          arg('flow-games.com', t.String),
        ],
        {
          limit: 9999,
          authorizations: [
            fcl.authz,
            userAuthorizationFunction(
              gameAccountPrivateKey,
              '0',
              gameAccountAddress
            ),
          ],
        },
        {
          title: 'Connecting Wallet to Game Account',
        }
      )
      return txid
    }
  }, [executeTransaction, gameAccountPrivateKey, gameAccountAddress])

  useEffect(() => {
    const fn = async () => {
      const isUserAccountConnectedToChildAccount =
        await checkIsUserAccountConnectedToChildAccount()
      if (currentUser?.addr && !isUserAccountConnectedToChildAccount) {
        connectUserAccountToChildAccount()
      }
    }
    fn()
  }, [
    currentUser?.addr,
    gameAccountPrivateKey,
    gameAccountAddress,
    checkIsUserAccountConnectedToChildAccount,
    connectUserAccountToChildAccount,
  ])

  useEffect(() => {
    checkIsUserAccountInitialized()
    checkIsUserAccountConnectedToChildAccount()
  }, [checkIsUserAccountInitialized, checkIsUserAccountConnectedToChildAccount])

  const value = {
    isAccountInitStateLoading,
    isAccountInitialized,
    isUserAccountConnectedToGameAccount,
    checkIsUserAccountInitialized,
    checkIsUserAccountConnectedToChildAccount,
    connectUserAccountToChildAccount,
  }

  return <UserContext.Provider value={value}>{children}</UserContext.Provider>
}
