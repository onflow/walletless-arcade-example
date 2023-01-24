import {
  createContext,
  useContext,
  useCallback,
  useEffect,
  useState,
} from "react";
import { useFclContext } from "contexts";
import type { ReactNode } from "react";
import IS_GAME_PIECE_NFT_COLLECTION_CONFIGURED from "flow/cadence/scripts/game_piece_nft/is-game-piece-nft-collection-configured";
import { useGameAccountContext } from "./GameAccountContext";

interface Props {
  children?: ReactNode;
}

interface IUserContext {
  isAccountInitialized: boolean;
  isAccountInitStateLoading: boolean;
}

export const UserContext = createContext<IUserContext>({
  isAccountInitialized: false,
  isAccountInitStateLoading: false,
});

export const useUserContext = () => useContext(UserContext);

export default function UserContextProvider({ children }: Props) {
  const [isAccountInitStateLoading, setIsAccountInitStateLoading] =
    useState(false);
  const [isAccountInitialized, setIsAccountInitialized] = useState(false);
  const { currentUser, executeScript } = useFclContext();

  const { gameAccountPublicKey } = useGameAccountContext();

  const checkIsUserAccountInitialized = useCallback(async () => {
    if (currentUser?.addr && gameAccountPublicKey) {
      setIsAccountInitStateLoading(true);
      // TODO: Also check for child account linked properly to parent account
      const isUserInitializedForRps: boolean = await executeScript(
        IS_GAME_PIECE_NFT_COLLECTION_CONFIGURED,
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        (arg: any, t: any) => [
          arg(currentUser.addr, t.Address)
        ]
      );
      setIsAccountInitStateLoading(false);
      setIsAccountInitialized(isUserInitializedForRps);
    }
  }, [currentUser?.addr, executeScript, gameAccountPublicKey]);

  useEffect(() => {
    checkIsUserAccountInitialized();
  }, [checkIsUserAccountInitialized]);

  const value = {
    isAccountInitStateLoading,
    isAccountInitialized,
    checkIsUserAccountInitialized,
  };

  return <UserContext.Provider value={value}>{children}</UserContext.Provider>;
}
