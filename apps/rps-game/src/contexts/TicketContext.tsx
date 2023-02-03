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
import GET_BALANCE_OF_ALL_CHILD_ACCOUNTS from "../../cadence/scripts/ticket-token/get-balance-of-all-child-accounts"
import GET_BALANCE from "../../cadence/scripts/ticket-token/get-balance"

interface Props {
  children?: ReactNode;
}

interface ITicketContext {
  ticketAmount: string | null;
  getTicketAmount: (address: string, isParentAccount: boolean) => Promise<string | null>;
  mintTickets: (destinationAddress: string, amount: string) => Promise<void>
}

const initialState: ITicketContext = {
  ticketAmount: null,
  getTicketAmount: function (address: string, isParentAccount: boolean): Promise<string | null> {
    throw new Error(`Function not implemented.`);
  },
  mintTickets: function (destinationAddress: string, amount: string): Promise<void> {
    throw new Error(`Function not implemented.`);
  },
};

export const TicketContext =
  createContext<ITicketContext>(initialState);

export const useTicketContext = () => useContext(TicketContext);

export default function TicketContextProvider({ children }: Props) {
  const { currentUser, executeScript } = useFclContext();
  const [ticketAmount, setTicketAmount] = useState<null | string>(
    null
  );

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

          console.log("childAccountsBalance", childAccountsBalance)

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
    currentUser
  ]);

  const value = {
    ticketAmount,
    getTicketAmount,
    mintTickets
  };

  return (
    <TicketContext.Provider value={value}>
      {children}
    </TicketContext.Provider>
  );
}
 