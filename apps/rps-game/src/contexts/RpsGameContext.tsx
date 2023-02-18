import {
  createContext,
  useContext,
  useEffect,
  useCallback,
  useReducer,
  useMemo,
  useState,
} from 'react'
import type { ReactNode } from 'react'
import { useFclContext, useTicketContext } from 'shared'
import { useGameAccountContext } from './GameAccountContext'
import WALLETLESS_ONBOARDING from '../../cadence/transactions/onboarding/walletless-onboarding'
import SETUP_NEW_SINGLE_PLAYER_MATCH from '../../cadence/transactions/rock-paper-scissors-game/game-player/setup-new-singleplayer-match'
import GET_GAME_PLAYER_ID from '../../cadence/scripts/rock-paper-scissors-game/get-game-player-id'
import SUBMIT_BOTH_SINGLE_PLAYER_MOVES from '../../cadence/transactions/rock-paper-scissors-game/game-player/submit-both-singleplayer-moves'
import GET_COLLECTION_IDS from '../../cadence/scripts/gamepiece-nft/get-collection-ids'
import GET_RPS_WIN_LOSS from '../../cadence/scripts/gamepiece-nft/get-rps-win-loss'
import {
  userAuthorizationFunction,
  adminAuthorizationFunction,
} from '../utils/authz-functions'
import RESOLVE_MATCH_AND_RETURN_NFTS from '../../cadence/transactions/rock-paper-scissors-game/game-player/resolve-match-and-return-nfts'

const LOCAL_STORAGE_GAME_MATCH_ID = 'LOCAL_STORAGE_GAME_MATCH_ID'
const LOCAL_STORAGE_GAME_PIECE_ID = 'LOCAL_STORAGE_GAME_PIECE_ID'

interface Props {
  children?: ReactNode
}

export enum GameStatus {
  UNPURCHASED = 'UNPURCHASED',
  UNLOADED = 'UNLOADED',
  UNINITIALIZED = 'UNINITIALIZED',
  INITIALIZED = 'INITIALIZED',
  READY = 'READY',
  PLAYING = 'PLAYING',
  ENDED = 'ENDED',
}

type Action =
  | { type: 'SET_IS_GAME_INITIALIZED'; isGameInitialized: boolean }
  | { type: 'SET_GAME_PIECE_PURCHASED'; isGamePiecePurchased: boolean }
  | { type: 'SET_GAME_PIECE_NFT_ID'; gamePieceNFTID: string | null }
  | { type: 'SET_GAME_PLAYER_ID'; gamePlayerID: string | null }
  | { type: 'SET_GAME_MATCH_ID'; gameMatchID: string | null }
  | { type: 'SET_GAME_STATUS'; gameStatus: GameStatus }
  | { type: 'SET_GAME_RESULT'; gameResult: any | null }
  | { type: 'SET_WIN_LOSS_RECORD'; winLossRecord: any | null }
  | { type: 'RESET_GAME' }
  | {
      type: 'SET_HANDLERS'
      getGamePieceNFTID: () => Promise<void>
      getWinLossRecord: () => Promise<void>
      setupNewSinglePlayerMatch: () => Promise<void>
      submitBothSinglePlayerMoves: (_move: number) => Promise<void>
      resolveMatchAndReturnNFTS: () => Promise<void>
      resetGame: () => Promise<void>
      setGamePiecePurchased: (isPurchased: boolean) => Promise<void>
    }

interface State {
  gameStatus: GameStatus
  isGamePiecePurchased: boolean
  gameMatchID: string | null
  gamePieceNFTID: string | null
  gamePlayerID: string | null
  gameResult: any | null
  winLossRecord: any | null
  isGameInitialized: boolean
  isGameInitializedStateLoading: boolean
  isPlaying: boolean
  setGamePiecePurchased: (isGamePiecePurchased: boolean) => Promise<void>
  setupNewSinglePlayerMatch: () => Promise<void>
  getGamePieceNFTID: () => Promise<void>
  getWinLossRecord: () => Promise<void>
  submitBothSinglePlayerMoves: (_move: number) => Promise<void>
  resolveMatchAndReturnNFTS: () => Promise<void>
  resetGame: () => Promise<void>
}

const initialState: State = {
  gameStatus: GameStatus.UNPURCHASED,
  isGamePiecePurchased: false,
  gameMatchID: (() => {
    if (typeof window !== 'undefined') {
      const gameMatchId = window.localStorage.getItem(
        LOCAL_STORAGE_GAME_MATCH_ID
      )
      if (typeof gameMatchId === 'string') return gameMatchId
    }
    return null
  })(),
  gamePlayerID: null,
  gamePieceNFTID: (() => {
    if (typeof window !== 'undefined') {
      const gamePieceNFTID = window.localStorage.getItem(
        LOCAL_STORAGE_GAME_PIECE_ID
      )
      if (typeof gamePieceNFTID === 'string') return gamePieceNFTID
    }
    return null
  })(),
  gameResult: null,
  winLossRecord: null,
  isGameInitialized: false,
  isGameInitializedStateLoading: false,
  isPlaying: false,
  setGamePiecePurchased: async function (
    isGamePiecePurchased: boolean
  ): Promise<void> {
    return undefined
  },
  setupNewSinglePlayerMatch: async function (): Promise<void> {
    return undefined
  },
  getGamePieceNFTID: async function (): Promise<void> {
    return undefined
  },
  getWinLossRecord: async function (): Promise<void> {
    return undefined
  },
  submitBothSinglePlayerMoves: async function (_move: number): Promise<void> {
    return undefined
  },
  resolveMatchAndReturnNFTS: async function (): Promise<void> {
    return undefined
  },
  resetGame: async function (): Promise<void> {
    return undefined
  },
}

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'SET_IS_GAME_INITIALIZED':
      return { ...state, isGameInitialized: action.isGameInitialized }
    case 'SET_GAME_PIECE_PURCHASED':
      return { ...state, isGamePiecePurchased: action.isGamePiecePurchased }
    case 'SET_GAME_PIECE_NFT_ID':
      if (typeof window !== 'undefined' && action.gamePieceNFTID) {
        window.localStorage.setItem(
          LOCAL_STORAGE_GAME_PIECE_ID,
          action.gamePieceNFTID
        )
      }
      return { ...state, gamePieceNFTID: action.gamePieceNFTID }
    case 'SET_GAME_PLAYER_ID':
      return { ...state, gamePlayerID: action.gamePlayerID }
    case 'SET_GAME_MATCH_ID':
      if (typeof window !== 'undefined' && action.gameMatchID) {
        window.localStorage.setItem(
          LOCAL_STORAGE_GAME_MATCH_ID,
          action.gameMatchID
        )
      }
      return { ...state, gameMatchID: action.gameMatchID }
    case 'SET_GAME_STATUS':
      if (
        action.gameStatus === GameStatus.ENDED &&
        typeof window !== 'undefined'
      ) {
        window.localStorage.removeItem(LOCAL_STORAGE_GAME_MATCH_ID)
        window.localStorage.removeItem(LOCAL_STORAGE_GAME_PIECE_ID)
      }
      if (
        action.gameStatus === GameStatus.PLAYING &&
        typeof window !== 'undefined'
      ) {
        if (state.gameMatchID) {
          window.localStorage.setItem(
            LOCAL_STORAGE_GAME_MATCH_ID,
            state.gameMatchID
          )
        }
        if (state.gamePieceNFTID) {
          window.localStorage.setItem(
            LOCAL_STORAGE_GAME_PIECE_ID,
            state.gamePieceNFTID
          )
        }
      }
      return {
        ...state,
        gameStatus: action.gameStatus,
      }
    case 'SET_GAME_RESULT':
      return {
        ...state,
        gameResult: action.gameResult,
      }
    case 'SET_WIN_LOSS_RECORD':
      return {
        ...state,
        winLossRecord: action.winLossRecord,
      }
    case 'SET_HANDLERS':
      return {
        ...state,
        submitBothSinglePlayerMoves: action.submitBothSinglePlayerMoves,
        setupNewSinglePlayerMatch: action.setupNewSinglePlayerMatch,
        getGamePieceNFTID: action.getGamePieceNFTID,
        resolveMatchAndReturnNFTS: action.resolveMatchAndReturnNFTS,
        getWinLossRecord: action.getWinLossRecord,
        setGamePiecePurchased: action.setGamePiecePurchased,
        resetGame: action.resetGame,
      }
    case 'RESET_GAME':
      if (typeof window !== 'undefined') {
        window.localStorage.removeItem(LOCAL_STORAGE_GAME_MATCH_ID)
        window.localStorage.removeItem(LOCAL_STORAGE_GAME_PIECE_ID)
      }
      return {
        ...state,
        gameMatchID: null,
      }
    default:
      return state
  }
}

// Selectors
const getIsPlaying = (
  state: State,
  gameAccountAddress: string | null,
  isLoaded: boolean
) => {
  if (state) {
    const {
      isGameInitialized,
      gamePieceNFTID,
      gamePlayerID,
      gameMatchID,
      isGamePiecePurchased,
    } = state
    return (
      isGameInitialized &&
      isGamePiecePurchased &&
      gamePieceNFTID &&
      gamePlayerID &&
      gameMatchID &&
      gameAccountAddress &&
      isLoaded
    )
  } else {
    return null
  }
}

const getIsReady = (
  state: State,
  gameAccountAddress: string | null,
  isLoaded: boolean
) => {
  if (state) {
    const {
      isGameInitialized,
      gamePieceNFTID,
      gamePlayerID,
      isGamePiecePurchased,
    } = state
    return (
      isGameInitialized &&
      isGamePiecePurchased &&
      gamePieceNFTID &&
      gamePlayerID &&
      gameAccountAddress &&
      isLoaded
    )
  } else {
    return null
  }
}

const getIsInitialized = (
  state: State,
  gameAccountAddress: string | null,
  isLoaded: boolean
) => {
  if (state) {
    const { isGameInitialized, isGamePiecePurchased } = state
    return isGameInitialized && isGamePiecePurchased && isLoaded
  } else {
    return null
  }
}

export const RpsGameContext = createContext<{
  state: State
  dispatch: React.Dispatch<Action>
  gameAccountAddress: string | null
  gameAccountPublicKey: string | null
  loadingOpponentMove: boolean
  setLoadingOpponentMove: React.Dispatch<React.SetStateAction<boolean>>
}>({
  state: initialState,
  dispatch: () => null,
  gameAccountAddress: null,
  gameAccountPublicKey: null,
  loadingOpponentMove: false,
  setLoadingOpponentMove: () => null,
})

export const useRpsGameContext = () => useContext(RpsGameContext)

export default function RpsGameContextProvider({ children }: Props) {
  const [loadingOpponentMove, setLoadingOpponentMove] = useState<boolean>(false)

  const [state, dispatch] = useReducer(reducer, initialState)
  const {
    gameStatus,
    isGameInitialized,
    gamePieceNFTID,
    gameMatchID,
    gamePlayerID,
    isGamePiecePurchased,
  } = state

  const {
    currentUser,
    executeScript,
    executeTransaction,
    getTransactionStatusOnSealed,
  } = useFclContext()

  const { getTicketAmount, mintTickets } = useTicketContext()

  const {
    gameAccountAddress,
    gameAccountPublicKey,
    gameAccountPrivateKey,
    getGameAccountAddressFromGameAdmin,
    isLoaded,
    loadGameAccount,
  } = useGameAccountContext()

  const isPlaying = useMemo(
    () => getIsPlaying(state, gameAccountAddress, isLoaded),
    [state, gameAccountAddress, isLoaded]
  )

  const isReady = useMemo(
    () => getIsReady(state, gameAccountAddress, isLoaded),
    [state, gameAccountAddress, isLoaded]
  )

  const isInitialized = useMemo(
    () => getIsInitialized(state, gameAccountAddress, isLoaded),
    [state, gameAccountAddress, isLoaded]
  )

  const setGamePiecePurchased = useCallback(async (isPurchased: boolean) => {
    dispatch({
      type: 'SET_GAME_PIECE_PURCHASED',
      isGamePiecePurchased: isPurchased,
    })
  }, [])

  const checkGameClientInitialized = useCallback(async () => {
    if (!isLoaded) return

    if (!isGameInitialized && !gameAccountAddress && gameAccountPublicKey) {
      const txid = await executeTransaction(
        WALLETLESS_ONBOARDING,
        (arg: any, t: any) => [
          arg(gameAccountPublicKey, t.String),
          arg('1.0', t.UFix64),
          arg('RPS Proxy Account', t.String),
          arg('Proxy Account for Flow RPS', t.String),
          arg('flow-games.com/icon.png', t.String),
          arg('flow-games.com', t.String),
          arg('0', t.Int),
          arg('0', t.Int),
          arg('0', t.Int),
          arg('0', t.Int),
        ],
        {
          limit: 9999,
          payer: adminAuthorizationFunction,
          proposer: adminAuthorizationFunction,
          authorizations: [adminAuthorizationFunction],
        }
      )

      await getGameAccountAddressFromGameAdmin(gameAccountPublicKey)

      dispatch({
        type: 'SET_IS_GAME_INITIALIZED',
        isGameInitialized: true,
      })
    } else if (!isGameInitialized && gameAccountAddress) {
      dispatch({
        type: 'SET_IS_GAME_INITIALIZED',
        isGameInitialized: true,
      })
    }
  }, [
    isLoaded,
    isGameInitialized,
    gameAccountAddress,
    gameAccountPublicKey,
    executeTransaction,
    getGameAccountAddressFromGameAdmin,
  ])

  const getGamePieceNFTID = useCallback(async () => {
    if (isGameInitialized && gameAccountAddress) {
      const playerAddress = gameAccountAddress

      const res = await executeScript(
        GET_COLLECTION_IDS,
        (arg: any, t: any) => [arg(playerAddress, t.Address)]
      )

      if (!Array.isArray(res) || res.length <= 0) return

      dispatch({
        type: 'SET_GAME_PIECE_NFT_ID',
        gamePieceNFTID: res[0],
      })
    }
  }, [isGameInitialized, gameAccountAddress, executeScript])

  const getGamePlayerID = useCallback(async () => {
    if (isGameInitialized && gameAccountAddress) {
      const playerAddress = gameAccountAddress

      const res = await executeScript(
        GET_GAME_PLAYER_ID,
        (arg: any, t: any) => [arg(playerAddress, t.Address)]
      )

      dispatch({
        type: 'SET_GAME_PLAYER_ID',
        gamePlayerID: res,
      })
    }
  }, [isGameInitialized, gameAccountAddress, executeScript])

  const setupNewSinglePlayerMatch = useCallback(async () => {
    if (gamePieceNFTID && gameAccountPrivateKey && gameAccountAddress) {
      const submittingNFTID = gamePieceNFTID
      const matchTimeLimitInMinutes = 5

      const txId = await executeTransaction(
        SETUP_NEW_SINGLE_PLAYER_MATCH,
        (arg: any, t: any) => [
          arg(submittingNFTID, t.UInt64),
          arg(matchTimeLimitInMinutes, t.UInt),
        ],
        {
          limit: 9999,
          payer: adminAuthorizationFunction,
          proposer: userAuthorizationFunction(
            gameAccountPrivateKey,
            '0',
            gameAccountAddress
          ),
          authorizations: [
            userAuthorizationFunction(
              gameAccountPrivateKey,
              '0',
              gameAccountAddress
            ),
          ],
        }
      )
      if (!txId) return

      const transactionStatus = await getTransactionStatusOnSealed(txId)
      const transactionEvents = transactionStatus?.events

      if (!transactionEvents || !Array.isArray(transactionEvents)) return

      const newMatchCreatedEvent = transactionEvents.find(event =>
        event?.type.includes('NewMatchCreated')
      )
      const matchId = newMatchCreatedEvent.data?.matchID

      dispatch({
        type: 'SET_GAME_MATCH_ID',
        gameMatchID: matchId,
      })
    }
  }, [
    gamePieceNFTID,
    gameAccountPrivateKey,
    gameAccountAddress,
    executeTransaction,
    getTransactionStatusOnSealed,
  ])

  const submitBothSinglePlayerMoves = useCallback(
    async (_move: number) => {
      if (
        gamePieceNFTID &&
        gameMatchID &&
        gameAccountPrivateKey &&
        gameAccountAddress
      ) {
        const matchID = gameMatchID
        const move = _move // 0 = rock, 1 = paper, 2 = scissors
        setLoadingOpponentMove(true)
        const txId = await executeTransaction(
          SUBMIT_BOTH_SINGLE_PLAYER_MOVES,
          (arg: any, t: any) => [arg(matchID, t.UInt64), arg(move, t.UInt8)],
          {
            limit: 9999,
            payer: adminAuthorizationFunction,
            proposer: userAuthorizationFunction(
              gameAccountPrivateKey,
              '0',
              gameAccountAddress
            ),
            authorizations: [
              userAuthorizationFunction(
                gameAccountPrivateKey,
                '0',
                gameAccountAddress
              ),
            ],
          }
        )
      }
    },
    [
      gamePieceNFTID,
      gameMatchID,
      executeTransaction,
      gameAccountPrivateKey,
      gameAccountAddress,
    ]
  )

  const resolveMatchAndReturnNFTS = useCallback(async () => {
    if (gameMatchID && gameAccountPrivateKey && gameAccountAddress) {
      const matchID = gameMatchID

      const txId = await executeTransaction(
        RESOLVE_MATCH_AND_RETURN_NFTS,
        (arg: any, t: any) => [arg(matchID, t.UInt64)],
        {
          limit: 9999,
          payer: adminAuthorizationFunction,
          proposer: userAuthorizationFunction(
            gameAccountPrivateKey,
            '0',
            gameAccountAddress
          ),
          authorizations: [
            userAuthorizationFunction(
              gameAccountPrivateKey,
              '0',
              gameAccountAddress
            ),
          ],
        }
      )

      if (!txId) return
      const transactionStatus = await getTransactionStatusOnSealed(txId)
      const transactionEvents = transactionStatus?.events

      if (!transactionEvents || !Array.isArray(transactionEvents)) return

      const newMatchCreatedEvent = transactionEvents.find(event =>
        event?.type.includes('MatchOver')
      )
      const player1ID = newMatchCreatedEvent.data?.player1ID
      const player1MoveRawValue = newMatchCreatedEvent.data?.player1MoveRawValue
      const player2ID = newMatchCreatedEvent.data?.player2ID
      const player2MoveRawValue = newMatchCreatedEvent.data?.player2MoveRawValue
      const winningGamePlayer = newMatchCreatedEvent.data?.winningGamePlayer
      const winningNFTID = newMatchCreatedEvent.data?.winningNFTID
      const returnedNFTIDs = newMatchCreatedEvent.data?.returnedNFTIDs

      const endgame = {
        matchID,
        player1ID,
        player1MoveRawValue,
        player2ID,
        player2MoveRawValue,
        winningGamePlayer,
        winningNFTID,
        returnedNFTIDs,
      }

      const isPlayerWinner = gamePlayerID === winningGamePlayer

      if (isPlayerWinner) {
        await mintTickets(gameAccountAddress, '10.0')
      }

      setLoadingOpponentMove(false)
      dispatch({
        type: 'SET_GAME_RESULT',
        gameResult: endgame,
      })

      dispatch({
        type: 'SET_GAME_STATUS',
        gameStatus: GameStatus.ENDED,
      })
    }
  }, [
    gameMatchID,
    gameAccountPrivateKey,
    gameAccountAddress,
    executeTransaction,
    getTransactionStatusOnSealed,
    gamePlayerID,
    mintTickets,
  ])

  const getWinLossRecord = useCallback(async () => {
    if (isGameInitialized && gameAccountAddress && gamePieceNFTID) {
      const playerAddress = gameAccountAddress
      const nftID = gamePieceNFTID

      const res = await executeScript(GET_RPS_WIN_LOSS, (arg: any, t: any) => [
        arg(playerAddress, t.Address),
        arg(nftID, t.UInt64),
      ])

      dispatch({
        type: 'SET_WIN_LOSS_RECORD',
        winLossRecord: res,
      })
    }
  }, [isGameInitialized, gameAccountAddress, gamePieceNFTID, executeScript])

  const resetGame = useCallback(async () => {
    dispatch({
      type: 'RESET_GAME',
    })
  }, [])

  useEffect(() => {
    dispatch({
      type: 'SET_HANDLERS',
      setupNewSinglePlayerMatch,
      getGamePieceNFTID,
      submitBothSinglePlayerMoves,
      resolveMatchAndReturnNFTS,
      resetGame,
      getWinLossRecord,
      setGamePiecePurchased,
    })
  }, [
    submitBothSinglePlayerMoves,
    setupNewSinglePlayerMatch,
    getGamePieceNFTID,
    resolveMatchAndReturnNFTS,
    resetGame,
    getWinLossRecord,
    setGamePiecePurchased,
  ])

  useEffect(() => {
    if (isPlaying) {
      dispatch({ type: 'SET_GAME_STATUS', gameStatus: GameStatus.PLAYING })
      return
    }
    if (isReady) {
      dispatch({ type: 'SET_GAME_STATUS', gameStatus: GameStatus.READY })
      return
    }
    if (isInitialized) {
      dispatch({ type: 'SET_GAME_STATUS', gameStatus: GameStatus.INITIALIZED })
      return
    }
    if (isLoaded) {
      dispatch({
        type: 'SET_GAME_STATUS',
        gameStatus: GameStatus.UNINITIALIZED,
      })
      return
    }
    if (isGamePiecePurchased) {
      dispatch({
        type: 'SET_GAME_STATUS',
        gameStatus: GameStatus.UNLOADED,
      })
      return
    }
    dispatch({
      type: 'SET_GAME_STATUS',
      gameStatus: GameStatus.UNPURCHASED,
    })
    return
  }, [
    currentUser?.addr,
    isPlaying,
    isReady,
    isInitialized,
    isGamePiecePurchased,
    isLoaded,
  ])

  useEffect(() => {
    switch (gameStatus) {
      case GameStatus.UNLOADED:
        loadGameAccount()
        return
      case GameStatus.UNINITIALIZED:
        checkGameClientInitialized()
        return
      case GameStatus.INITIALIZED:
        getGamePieceNFTID()
        getWinLossRecord()
        getGamePlayerID()
        return
      case GameStatus.ENDED:
        getWinLossRecord()
        return
    }
  }, [
    gameStatus,
    isPlaying,
    isReady,
    isInitialized,
    isGamePiecePurchased,
    gameMatchID,
    gamePlayerID,
    gameAccountPublicKey,
    gameAccountAddress,
    checkGameClientInitialized,
    getGameAccountAddressFromGameAdmin,
    loadGameAccount,
    getGamePieceNFTID,
    getWinLossRecord,
    getGamePlayerID,
  ])

  useEffect(() => {
    const fn = async () => {
      if (gameAccountAddress) {
        await getTicketAmount(gameAccountAddress, false)
      }
    }
    fn()
    const id = setInterval(fn, 5000)
    return () => clearInterval(id)
  }, [gameAccountAddress, gameStatus, getTicketAmount])

  const providerProps = useMemo(
    () => ({
      state,
      dispatch,
      gameAccountAddress,
      gameAccountPublicKey,
      setGamePiecePurchased,
      isPlaying,
      loadingOpponentMove,
      setLoadingOpponentMove,
    }),
    [
      state,
      dispatch,
      gameAccountAddress,
      gameAccountPublicKey,
      setGamePiecePurchased,
      isPlaying,
      loadingOpponentMove,
      setLoadingOpponentMove,
    ]
  )

  return (
    <RpsGameContext.Provider value={{ ...providerProps }}>
      {children}
    </RpsGameContext.Provider>
  )
}
