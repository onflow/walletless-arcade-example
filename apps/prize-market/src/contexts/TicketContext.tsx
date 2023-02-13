import {
  useEffect,
  useState,
  useCallback,
  useContext,
  createContext,
} from 'react'
import type { ReactNode } from 'react'
import { useFclContext } from 'ui'
import * as fcl from '@onflow/fcl'
import MINT_RAINBOW_DUCK_PAYING_WITH_CHILD_VAULT from '../../cadence/transactions/arcade-prize/mint-rainbow-duck-paying-with-child-vault'
import GET_ALL_NFT_DISPLAY_VIEWS from '../../cadence/scripts/arcade-prize/get-all-nft-display-views'
import GET_BALANCE_OF_ALL_CHILD_ACCOUNTS from '../../cadence/scripts/ticket-token/get-balance-of-all-child-accounts'
import GET_BALANCE from '../../cadence/scripts/ticket-token/get-balance'
import {
  userAuthorizationFunction,
  adminAuthorizationFunction,
} from '../utils/authz-functions'

interface Props {
  children?: ReactNode
}

interface ITicketContext {
  totalTicketBalance: string | null
  childTicketVaultAddress: string | null
  ownedPrizes: null | any[]
  getOwnedPrizes: (address: string) => Promise<void>
  getTicketAmount: (
    address: string,
    isParentAccount: boolean
  ) => Promise<string | null>
  mintTickets: (destinationAddress: string, amount: string) => Promise<void>
  purchaseWithTickets: (
    fundingAddress: string,
    minterAddress: string
  ) => Promise<void>
}

const initialState: ITicketContext = {
  totalTicketBalance: null,
  childTicketVaultAddress: null,
  ownedPrizes: null,
  getOwnedPrizes: function (address: string): Promise<void> {
    throw new Error(`Function not implemented.`)
  },
  getTicketAmount: function (
    address: string,
    isParentAccount: boolean
  ): Promise<string | null> {
    throw new Error(`Function not implemented.`)
  },
  mintTickets: function (
    destinationAddress: string,
    amount: string
  ): Promise<void> {
    throw new Error(`Function not implemented.`)
  },
  purchaseWithTickets: function (
    fundingAddress: string,
    minterAddress: string
  ): Promise<void> {
    throw new Error(`Function not implemented.`)
  },
}

export const TicketContext = createContext<ITicketContext>(initialState)

export const useTicketContext = () => useContext(TicketContext)

export default function TicketContextProvider({ children }: Props) {
  const [totalTicketBalance, setTotalTicketBalance] = useState<null | string>(
    null
  )
  const [ownedPrizes, setOwnedPrizes] = useState<null | any[]>(null)
  const [childTicketVaultAddress, setChildTicketVaultAddress] = useState<
    null | string
  >(null)
  const { currentUser, executeScript, executeTransaction } = useFclContext()

  const purchaseWithTickets = useCallback(
    async (fundingAddress: string, minterAddress: string): Promise<void> => {
      await executeTransaction(
        MINT_RAINBOW_DUCK_PAYING_WITH_CHILD_VAULT,
        (arg: any, t: any) => [
          arg(fcl.withPrefix(fundingAddress), t.Address),
          arg(fcl.withPrefix(minterAddress), t.Address),
        ],
        {
          limit: 9999,
          payer: fcl.authz,
          proposer: fcl.authz,
          authorizations: [fcl.authz],
        }
      )
    },
    []
  )

  const getOwnedPrizes = useCallback(
    async (address: string): Promise<void> => {
      try {
        const _ownedPrizes: any[] = await executeScript(
          GET_ALL_NFT_DISPLAY_VIEWS,
          (arg: any, t: any) => [arg(fcl.withPrefix(address), t.Address)]
        )
        setOwnedPrizes(_ownedPrizes)
      } catch (e) {
        return
      }
    },
    [executeScript, setOwnedPrizes]
  )

  const mintTickets = useCallback(
    async (destinationAddress: string, amount: string): Promise<void> => {
      try {
        await fetch(`/api/tickets/mint`, {
          method: 'POST',
          body: JSON.stringify({
            destinationAddress,
            amount,
          }),
        })
      } catch (e) {
        return
      }
    },
    []
  )

  const getTicketAmount = useCallback(
    async (
      address: string,
      isParentAccount: boolean
    ): Promise<string | null> => {
      if (address) {
        try {
          const parentBalance: string = await executeScript(
            GET_BALANCE,
            (arg: any, t: any) => [arg(fcl.withPrefix(address), t.Address)]
          )

          if (isParentAccount) {
            const childAccountsBalances: Record<number, string> =
              await executeScript(
                GET_BALANCE_OF_ALL_CHILD_ACCOUNTS,
                (arg: any, t: any) => [arg(fcl.withPrefix(address), t.Address)]
              )

            const childTicketVaultAddress =
              Object.keys(childAccountsBalances)[0] || null
            setChildTicketVaultAddress(childTicketVaultAddress)

            const sumOfChildAccountBalances = (
              childAccountsBalances: Record<string, string>
            ) =>
              Object.values(childAccountsBalances)
                .map(Number)
                .reduce((a, b) => a + b, 0)

            const summedBalance = Number(
              Number(parentBalance) +
                Number(sumOfChildAccountBalances(childAccountsBalances))
            ).toFixed(0)

            setTotalTicketBalance(Number(summedBalance).toFixed(0))
          }
        } catch (e) {
          return null
        }
      }
      return null
    },
    [setTotalTicketBalance, executeScript]
  )

  const value = {
    currentUser,
    childTicketVaultAddress,
    totalTicketBalance,
    ownedPrizes,
    getTicketAmount,
    getOwnedPrizes,
    mintTickets,
    purchaseWithTickets,
  }

  return (
    <TicketContext.Provider value={value}>{children}</TicketContext.Provider>
  )
}
