import { useState, useEffect, useCallback } from 'react'
import {
  FlashButton,
  Row,
  Modal,
  useAppContext,
  useFclContext,
  useTicketContext,
} from 'shared'
import { useRpsGameContext, GameStatus } from '../contexts'

type PlayerMove = 'rock' | 'paper' | 'scissors' | undefined

const GameView = () => {
  const { enabled } = useAppContext()
  const { currentUser } = useFclContext()

  const [purchaseSuccessModalOpen, setPurchaseSuccessModalOpen] =
    useState<boolean>(true)
  const [goToMarketplaceModalOpen, setGoToMarketplaceOpen] =
    useState<boolean>(false)
  const [playModalOpen, setPlayModalOpen] = useState<boolean>(false)

  const [locked, setLocked] = useState(false)
  const [playerMove, setPlayerMove] = useState<PlayerMove>(undefined)
  const [opponentMove, setOpponentMove] = useState<PlayerMove>(undefined)
  const [message, setMessage] = useState<string>('')

  const {
    state: {
      gameStatus,
      gameMatchID,
      gamePieceNFTID,
      gameResult,
      isGameInitialized,
      isGameInitializedStateLoading,
      setupNewSinglePlayerMatch,
      submitBothSinglePlayerMoves,
      resolveMatchAndReturnNFTS,
      resetGame,
      gamePlayerID,
      winLossRecord,
    },
  } = useRpsGameContext()

  const { totalTicketBalance } = useTicketContext()

  const handleEndgame = useCallback(
    async function (gameResult: any) {
      const playerNFTID = gamePieceNFTID
      const playerID = gamePlayerID
      const {
        matchID,
        player1ID,
        player1MoveRawValue,
        player2ID,
        player2MoveRawValue,
        returnedNFTIDs,
        winningGamePlayer,
        winningNFTID,
      } = gameResult

      const playerMove =
        playerID === player1ID ? player1MoveRawValue : player2MoveRawValue
      const opponentMove =
        playerID === player1ID ? player2MoveRawValue : player1MoveRawValue

      let playerMoveString: PlayerMove
      if (playerMove === '0') {
        playerMoveString = 'rock'
      } else if (playerMove === '1') {
        playerMoveString = 'paper'
      } else if (playerMove === '2') {
        playerMoveString = 'scissors'
      }

      let opponentMoveString: PlayerMove
      if (opponentMove === '0') {
        opponentMoveString = 'rock'
        setOpponentMove('rock')
      } else if (opponentMove === '1') {
        opponentMoveString = 'paper'
        setOpponentMove('paper')
      } else if (opponentMove === '2') {
        opponentMoveString = 'scissors'
        setOpponentMove('scissors')
      }

      if (winningNFTID === null) {
        setMessage(
          `You played ${playerMoveString} and tied ${opponentMoveString}!`
        )
      }

      const isPlayerWinner = playerID === winningGamePlayer

      if (isPlayerWinner) {
        setMessage(
          'You won! You get 10 tickets 🎟! Connect your wallet now to redeem your tickets for use on the market, go to Settings > Connect Wallet'
        )
      } else if (winningNFTID && !isPlayerWinner) {
        setMessage(
          `You played ${playerMoveString} and lost against ${opponentMoveString}!`
        )
      }
    },
    [gamePieceNFTID, gamePlayerID]
  )

  useEffect(() => {
    if (gameStatus === GameStatus.ENDED) {
      handleEndgame(gameResult)
    }
  }, [gameResult, gameStatus, handleEndgame])

  useEffect(() => {
    setPlayModalOpen(gameStatus === GameStatus.ENDED)
  }, [gameStatus])

  const toggleDisableButtons = () => {
    setLocked(locked => !locked)
  }

  const handlePlayAgain = async () => {
    if (gameStatus !== GameStatus.ENDED) return
    setPlayModalOpen(false)
    setPurchaseSuccessModalOpen(false)

    setPlayerMove(undefined)
    setOpponentMove(undefined)
    await resetGame()
    await setupNewSinglePlayerMatch()
  }

  const handlePlay = async () => {
    if (gameStatus !== GameStatus.READY) return
    setPlayModalOpen(false)
    setPurchaseSuccessModalOpen(false)

    await setupNewSinglePlayerMatch()
  }

  const handleMove = async (command: string) => {
    if (gameStatus !== GameStatus.PLAYING) return

    if (command === 'r') {
      setPlayerMove('rock')
      await submitBothSinglePlayerMoves(0)
    } else if (command === 'p') {
      setPlayerMove('paper')
      await submitBothSinglePlayerMoves(1)
    } else if (command === 's') {
      setPlayerMove('scissors')
      await submitBothSinglePlayerMoves(2)
    }

    await resolveMatchAndReturnNFTS()
  }

  useEffect(() => {
    if (currentUser?.addr) {
      setGoToMarketplaceOpen(true)
    }
  }, [currentUser?.addr])

  return (
    <div className="container m-auto">
      {totalTicketBalance && (
        <div className="mb-12 flex w-full justify-center text-2xl text-green-500 md:mb-24">
          <span className="text-xl font-extrabold">
            🎟 Tickets: {totalTicketBalance}
          </span>
        </div>
      )}
      <div className="container m-auto grid grid-cols-1 gap-4 md:my-10 md:grid-cols-3">
        <div className="flex h-60 items-center justify-center rounded-md border border-green-500 border-opacity-100 md:h-96">
          {playerMove === 'rock' && (
            <span className="text-9xl font-extrabold">🪨</span>
          )}
          {playerMove === 'paper' && (
            <span className="text-9xl font-extrabold">📄</span>
          )}
          {playerMove === 'scissors' && (
            <span className="text-9xl font-extrabold">✂️</span>
          )}
          {!playerMove && gameStatus === GameStatus.PLAYING && (
            <span className="text-9xl font-extrabold">❓</span>
          )}
        </div>

        <div className="flex min-h-full items-center justify-center">
          <div className="tile flex h-24 w-24 items-center justify-center bg-green-500" />

          <code className="m-4">vs.</code>
          <div className="tile flex h-24 w-24 items-center justify-center bg-pink-500" />
        </div>

        <div className="flex h-60 items-center justify-center rounded-md border border-pink-500 border-opacity-100 md:h-96">
          {opponentMove === 'rock' && (
            <span className="text-9xl font-extrabold">🪨</span>
          )}
          {opponentMove === 'paper' && (
            <span className="text-9xl font-extrabold">📄</span>
          )}
          {opponentMove === 'scissors' && (
            <span className="text-9xl font-extrabold">✂️</span>
          )}
          {!playerMove && gameStatus === GameStatus.PLAYING && (
            <span className="text-9xl font-extrabold">❓</span>
          )}
        </div>
      </div>

      <Row>
        {gameStatus === GameStatus.PLAYING && (
          <>
            <FlashButton onClick={() => handleMove('r')} disabled={locked}>
              Rock
            </FlashButton>
            <FlashButton onClick={() => handleMove('p')} disabled={locked}>
              Paper
            </FlashButton>
            <FlashButton onClick={() => handleMove('s')} disabled={locked}>
              Scissors
            </FlashButton>
          </>
        )}
        {(gameStatus === GameStatus.READY ||
          gameStatus === GameStatus.ENDED) && (
          <FlashButton
            onClick={
              gameStatus === GameStatus.READY ? handlePlay : handlePlayAgain
            }
            disabled={locked}
          >
            {gameStatus === GameStatus.READY ? ' Play ' : 'Play Again'}
          </FlashButton>
        )}
      </Row>
      <div className="mt-12 flex w-full flex-row items-center justify-center md:mt-24">
        <div className="flex w-full items-center justify-center space-x-4 text-2xl font-extrabold text-green-500">
          <span> Wins: {winLossRecord?.wins ?? 0}</span>
          <span> Losses: {winLossRecord?.losses ?? 0}</span>
          <span> Ties: {winLossRecord?.ties ?? 0}</span>
        </div>
      </div>
      <Modal
        isOpen={goToMarketplaceModalOpen && !enabled}
        handleClose={() => setGoToMarketplaceOpen(false)}
        handleOpen={() => setGoToMarketplaceOpen(true)}
        dialog={`
          Now that you've connected your wallet, head to the marketplace to spend your tickets on an NFT prize!
        `}
        buttonText={'Go to Marketplace'}
        buttonFunc={() =>
          window.open(process.env.NEXT_PUBLIC_MARKETPLACE_URL || '')
        }
      />
      <Modal
        isOpen={purchaseSuccessModalOpen && !enabled}
        handleClose={() => setPurchaseSuccessModalOpen(false)}
        handleOpen={() => null}
        dialog={`Your payment has been successfully submitted. We’ve sent
        you an email with all of the details of your order.`}
        buttonText={"Let's play!"}
        buttonFunc={
          gameStatus === GameStatus.READY
            ? handlePlay
            : () => setPurchaseSuccessModalOpen(false)
        }
      />
      <Modal
        isOpen={playModalOpen && !enabled}
        handleClose={() => setPlayModalOpen(false)}
        handleOpen={() => null}
        dialog={message}
        buttonText={'Continue'}
        buttonFunc={() => setPlayModalOpen(false)}
      />
    </div>
  )
}

export default GameView
