import {
  useEffect,
  useState,
  useCallback,
  useContext,
  createContext,
} from "react";
import type { ReactNode } from "react";
import { useFclContext } from "./FclContext";

interface Props {
  children?: ReactNode;
}

interface ITicketContext {
  ticketAmount: string | null;
  getTicketAmount: () => Promise<string | null>;
}

const initialState: ITicketContext = {
  ticketAmount: null,
  getTicketAmount: function (): Promise<string | null> {
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

  const getTicketAmount = useCallback(async (): Promise<
    string | null
  > => {

    if (currentUser && currentUser?.addr) {
      // TODO: Execute required script
      const res: string = await executeScript(
        "stub",
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        (arg: any, t: any) => [
        ]
      );

      setTicketAmount(res);
      return res;
    }
    return null
  }, [
    setTicketAmount,
    executeScript,
    currentUser
  ]);

  useEffect(() => {
    getTicketAmount();
  }, [getTicketAmount]);

  const value = {
    ticketAmount,
    getTicketAmount
  };

  return (
    <TicketContext.Provider value={value}>
      {children}
    </TicketContext.Provider>
  );
}
