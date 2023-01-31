import { useState, useEffect, useCallback } from 'react'
import Image from 'next/image'
import { useFclContext, useRpsGameContext, GameStatus } from '../contexts'
import useUtils from '../utils'
import rock from '../../public/rock.png'
import paper from '../../public/static/paper.png'
import scissors from '../../public/static/scissors.png'
import { Button } from './button-v3'

const GameView = () => {
  const [locked, setLocked] = useState(false)
  const [playerMove, setPlayerMove] = useState(null)
  const { currentUser, connect, logout, executeTransaction, transaction } =
    useFclContext()
  const { gameAccountAddress } = useRpsGameContext()

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
    scissors,
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

      let playerMoveString
      if (playerMove === '0') {
        playerMoveString = 'Rock'
      } else if (playerMove === '1') {
        playerMoveString = 'Paper'
      } else if (playerMove === '2') {
        playerMoveString = 'Scissors'
      }

      let opponentMoveString
      if (opponentMove === '0') {
        opponentMoveString = 'Rock'
      } else if (opponentMove === '1') {
        opponentMoveString = 'Paper'
      } else if (opponentMove === '2') {
        opponentMoveString = 'Scissors'
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

  const printP1Move = async (move: string) => {
    console.log('printP1Move', move)
  }

  const printP2Move = async (move: string) => {
    console.log('printP2Move', move)
  }

  const handleResetAnswer = async (command: string) => {
    if (gameStatus !== GameStatus.ENDED) return

    if (command === 'y') {
      await resetGame()

      toggleDisableButtons()
    }
  }

  const handleMove = async (command: string) => {
    console.log('handleMove', command)

    if (gameStatus !== GameStatus.PLAYING) return
    toggleDisableButtons()

    if (command === 'r') {
      printP1Move('Rock')
      await submitBothSinglePlayerMoves(0)
    } else if (command === 'p') {
      printP1Move('Paper')
      await submitBothSinglePlayerMoves(1)
    } else if (command === 's') {
      printP1Move('Scissors')
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
            <div>
              <Image src={scissors} alt="Game Piece" width={500} height={500} />
            </div>
          </div>
        </section>
        <section id="middle">
          <h1 className="text-2xl text-gray-700">TIES</h1>
          <h2 className="text-3xl font-extrabold leading-normal text-gray-700 md:text-[3rem]">
            {winLossRecord?.ties ?? 0}
          </h2>
          <div></div>
        </section>
        <section id="opponent">
          <h1 className="text-2xl text-gray-700">OPPONENT</h1>
          <h2 className="text-3xl font-extrabold leading-normal text-gray-700 md:text-[3rem]">
            {winLossRecord?.losses ?? 0}
          </h2>
          <div>
            <div>
              <Image src={scissors} alt="Game Piece" width={500} height={500} />
            </div>
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
