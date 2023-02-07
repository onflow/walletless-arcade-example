import {
  useEffect,
  useState,
  useCallback,
  useContext,
  createContext,
} from "react";
import type { ReactNode } from "react";
import { useFclContext } from "./FclContext";
import * as fcl from "@onflow/fcl";
import MINT_RAINBOW_DUCK_PAYING_WITH_CHILD_VAULT from "../../cadence/transactions/arcade-prize/mint-rainbow-duck-paying-with-child-vault"
import GET_BALANCE_OF_ALL_CHILD_ACCOUNTS from "../../cadence/scripts/ticket-token/get-balance-of-all-child-accounts"
import GET_BALANCE from "../../cadence/scripts/ticket-token/get-balance"
import {
  userAuthorizationFunction,
  adminAuthorizationFunction,
} from '../utils/authz-functions'

interface Props {
  children?: ReactNode;
}

interface ITicketContext {
  ticketAmount: string | null;
  getTicketAmount: (address: string, isParentAccount: boolean) => Promise<string | null>;
  mintTickets: (destinationAddress: string, amount: string) => Promise<void>;
  purchaseWithTickets: (fundingChildAddress: string, minterAddress: string) => Promise<void>;
}

const initialState: ITicketContext = {
  ticketAmount: null,
  getTicketAmount: function (address: string, isParentAccount: boolean): Promise<string | null> {
    throw new Error(`Function not implemented.`);
  },
  mintTickets: function (destinationAddress: string, amount: string): Promise<void> {
    throw new Error(`Function not implemented.`);
  },
  purchaseWithTickets: function (fundingChildAddress: string, minterAddress: string): Promise<void> {
    throw new Error(`Function not implemented.`);
  },
};

export const TicketContext =
  createContext<ITicketContext>(initialState);

export const useTicketContext = () => useContext(TicketContext);

export default function TicketContextProvider({ children }: Props) {
  const { currentUser, executeScript, executeTransaction } = useFclContext();
  const [ticketAmount, setTicketAmount] = useState<null | string>(
    null
  );

  const purchaseWithTickets = useCallback(async (fundingChildAddress: string, minterAddress: string): Promise<void> => {
    await executeTransaction(
      MINT_RAINBOW_DUCK_PAYING_WITH_CHILD_VAULT,
      (arg: any, t: any) => [arg(fundingChildAddress, t.Address), arg(minterAddress, t.Address)],
      {
        limit: 9999,
        payer: fcl.authz,
        proposer: fcl.authz,
        authorizations: [fcl.authz]
      }
    );
  },
  [])

  const mintTickets = useCallback(async (destinationAddress: string, amount: string): Promise<void> => {
    try {
      await fetch(`/api/tickets/mint`, {
        method: "POST",
        body: JSON.stringify({
          destinationAddress,
          amount
        })
      })
    } catch (e) {
      return
    }
  }, 
  [])

  const getTicketAmount = useCallback(async (address: string, isParentAccount: boolean): Promise<
    string | null
  > => {
    if (address) {
      try {
        let balance: string = await executeScript(
          GET_BALANCE,
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          (arg: any, t: any) => [
            arg(fcl.withPrefix(address), t.Address)
          ]
        );

        if (isParentAccount) {
        // if (currentUser) {
          const childAccountsBalance = await executeScript(
            GET_BALANCE_OF_ALL_CHILD_ACCOUNTS,
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            (arg: any, t: any) => [
              arg(fcl.withPrefix(address), t.Address)
            ]
          );

          balance = Number(Number(balance) + Number(childAccountsBalance)).toFixed(8)
        }
        // }

        setTicketAmount(balance);
        return balance;
      } catch(e) {
        return null
      }
    }
    return null
  }, [
    setTicketAmount,
    executeScript,
  ]);

  const value = {
    currentUser,
    ticketAmount,
    getTicketAmount,
    mintTickets,
    purchaseWithTickets
  };

  return (
    <TicketContext.Provider value={value}>
      {children}
    </TicketContext.Provider>
  );
}
 