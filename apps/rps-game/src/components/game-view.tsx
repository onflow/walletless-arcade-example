import { useState, useEffect, useCallback } from 'react'
import { FlashButton, Row, Modal, useFclContext, useTicketContext } from 'shared'
import { useRpsGameContext, GameStatus } from '../contexts'

type PlayerMove = 'rock' | 'paper' | 'scissors' | undefined

const GameView = () => {
  const { currentUser } = useFclContext()

  const [goToMarketplaceModalOpen, setGoToMarketplaceOpen] =
    useState<boolean>(false)

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
        setMessage('You won! You get 10 tickets! 🎟')
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

  const handlePlayAgain = async () => {
    if (gameStatus !== GameStatus.ENDED) return

    setPlayerMove(undefined)
    setOpponentMove(undefined)
    await resetGame()
    await setupNewSinglePlayerMatch()
  }

  const handlePlay = async () => {
    if (gameStatus !== GameStatus.READY) return

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
    <div className="flex w-full flex-wrap">
      <Modal
        isOpen={goToMarketplaceModalOpen}
        handleClose={() => setGoToMarketplaceOpen(false)}
        handleOpen={() => setGoToMarketplaceOpen(true)}
        dialog={`
          Now that you've connected your wallet, head to the marketplace to spend your tickets on an NFT prize!
        `}
        buttonText={'Go to Marketplace'}
        buttonFunc={() =>
          window.location.replace(process.env.NEXT_PUBLIC_MARKETPLACE_URL || '')
        }
      />
      <Modal
        isOpen={
          gameStatus === GameStatus.READY || gameStatus === GameStatus.ENDED
        }
        handleClose={() => null}
        handleOpen={() => null}
        dialog={
          gameStatus === GameStatus.READY
            ? `Your payment has been successfully submitted. We’ve sent
          you an email with all of the details of your order.`
            : 'Play Again?'
        }
        buttonText={'Play'}
        buttonFunc={
          gameStatus === GameStatus.READY ? handlePlay : handlePlayAgain
        }
      />
      <div className="flex w-full">
        {gameStatus !== 'READY' && (
          <div className="flex w-full items-center justify-center space-x-4 pt-6 text-2xl text-blue-500">
            <div className="w-full w-1/2">
              <div className="flex justify-center text-green-500">Player</div>
            </div>
            <div className="w-full w-1/2">
              <div className="flex justify-center text-red-500">Opponent</div>
            </div>
          </div>
        )}
      </div>
      <Row>
        <div className="w-1/2">
          <div className="text-grey-dark flex justify-center">
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
        </div>
        <div className="w-1/2">
          <div className="text-grey-dark flex justify-center">
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
      </Row>

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
      </Row>
      <Row>
        <div className="flex w-full items-center justify-center space-x-4 text-2xl font-extrabold text-blue-500">
          <span> Wins: {winLossRecord?.wins ?? 0}</span>
          <span> Losses: {winLossRecord?.losses ?? 0}</span>
          <span> Ties: {winLossRecord?.ties ?? 0}</span>
        </div>
        {totalTicketBalance && (
          <div className="flex w-full items-center justify-center space-x-4 text-2xl text-blue-500">
            <span className="text-xl font-extrabold">
              🎟 Tickets: {totalTicketBalance}
            </span>
          </div>
        )}
      </Row>
    </div>
  )
}

export default GameView
