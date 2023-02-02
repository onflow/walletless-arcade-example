import { useState, useEffect, useCallback } from 'react'
import { useRpsGameContext, GameStatus } from '../contexts'
import useUtils from '../utils'
import { Button } from './button-v3'

type PlayerMove = 'rock' | 'paper' | 'scissors' | undefined

const GameView = () => {
  const [locked, setLocked] = useState(false)
  const [playerMove, setPlayerMove] = useState<PlayerMove>(undefined)
  const [opponentMove, setOpponentMove] = useState<PlayerMove>(undefined)

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

  const { delay } = useUtils()

  console.log('RPS GAME STATE', {
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
  })

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
        // tie
      }

      const isPlayerWinner = playerID === winningGamePlayer

      if (isPlayerWinner) {
        console.log('You won!')
      } else if (winningNFTID && !isPlayerWinner) {
        console.log(
          `You Played ${playerMoveString} and Lost against ${opponentMoveString}!`
        )
      }
      delay(3000).then(() => {
        console.log(`Shall we play again?`)
      })
    },
    [delay, gamePieceNFTID, gamePlayerID]
  )

  useEffect(() => {
    if (gameStatus === GameStatus.READY) {
      setupNewSinglePlayerMatch()
    }
    if (gameStatus === GameStatus.PLAYING) {
      console.log('gameStatus', gameStatus)
    }
    if (gameStatus === GameStatus.ENDED) {
      handleEndgame(gameResult)
    }
  }, [gameResult, gameStatus, handleEndgame, setupNewSinglePlayerMatch])

  const toggleDisableButtons = () => {
    setLocked(locked => !locked)
  }

  const handleResetAnswer = async (command: string) => {
    if (gameStatus !== GameStatus.ENDED) return

    if (command === 'y') {
      await resetGame()

      toggleDisableButtons()
    }
  }

  const handleMove = async (command: string) => {
    // if (gameStatus !== GameStatus.PLAYING) return
    toggleDisableButtons()

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

  return (
    <>
      <div className="mt-3 grid gap-3 pt-3 text-center md:grid-cols-3 lg:w-2/3">
        <section id="player">
          <h1 className="text-2xl text-gray-700">PLAYER</h1>
          <h2 className="text-3xl font-extrabold leading-normal text-gray-700 md:text-[3rem]">
            {winLossRecord?.wins ?? 0}
          </h2>
          <div>
            {playerMove === 'rock' && (
              <span className="text-9xl font-extrabold">🪨</span>
            )}
            {playerMove === 'paper' && (
              <span className="text-9xl font-extrabold">📄</span>
            )}
            {playerMove === 'scissors' && (
              <span className="text-9xl font-extrabold">✂️</span>
            )}
          </div>
        </section>
        <section id="middle">
          <h1 className="text-2xl text-gray-700">TIES</h1>
          <h2 className="text-3xl font-extrabold leading-normal text-gray-700 md:text-[3rem]">
            {winLossRecord?.ties ?? 0}
          </h2>
        </section>
        <section id="opponent">
          <h1 className="text-2xl text-gray-700">OPPONENT</h1>
          <h2 className="text-3xl font-extrabold leading-normal text-gray-700 md:text-[3rem]">
            {winLossRecord?.losses ?? 0}
          </h2>
          <div>
            {opponentMove === 'rock' && (
              <span className="text-9xl font-extrabold">🪨</span>
            )}
            {opponentMove === 'paper' && (
              <span className="text-9xl font-extrabold">📄</span>
            )}
            {opponentMove === 'scissors' && (
              <span className="text-9xl font-extrabold">✂️</span>
            )}
          </div>
        </section>
      </div>
      <div className="flex w-full items-center justify-center space-x-4 pt-6 text-2xl text-blue-500">
        <Button onClick={() => handleMove('r')} disabled={locked}>
          Rock
        </Button>
        <Button onClick={() => handleMove('p')} disabled={locked}>
          Paper
        </Button>
        <Button onClick={() => handleMove('s')} disabled={locked}>
          Scissors
        </Button>
      </div>
    </>
  )
}

export default GameView
