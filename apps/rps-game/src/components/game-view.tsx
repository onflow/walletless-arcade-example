import React, { useState, useEffect, useCallback } from 'react'
import {
  FlashButton,
  Row,
  Modal,
  Spinner,
  useAppContext,
  useFclContext,
  useTicketContext,
} from 'shared'
import Image from 'next/image'
import MonsterLogo from '../../public/static/monster-logo.png'
import MarketLogo from '../../public/static/market-logo.png'
import {
  useRpsGameContext,
  GameStatus,
  useGameAccountContext,
} from '../contexts'

type PlayerMove = 'rock' | 'paper' | 'scissors' | undefined

const GameView = () => {
  const { enabled, fullScreenLoading } = useAppContext()
  const { currentUser } = useFclContext()

  const [purchaseSuccessModalOpen, setPurchaseSuccessModalOpen] =
    useState<boolean>(true)
  const [goToMarketplaceModalOpen, setGoToMarketplaceOpen] =
    useState<boolean>(false)
  const [playModalOpen, setPlayModalOpen] = useState<boolean>(false)

  const [locked, setLocked] = useState(false)
  const [playerMove, setPlayerMove] = useState<PlayerMove>(undefined)
  const [opponentMove, setOpponentMove] = useState<PlayerMove>(undefined)
  const [message, setMessage] = useState<React.FC>(() => null)

  const {
    state: {
      gameStatus,
      gameMatchID,
      gamePieceNFTID,
      gameResult,
      setupNewSinglePlayerMatch,
      submitBothSinglePlayerMoves,
      resolveMatchAndReturnNFTS,
      resetGame,
      gamePlayerID,
      winLossRecord,
    },
    loadingOpponentMove,
    setLoadingOpponentMove,
  } = useRpsGameContext()

  const { totalTicketBalance } = useTicketContext()

  const { gameAccountAddress } = useGameAccountContext()

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
        const newMessage = function () {
          return (
            <div>
              {`You played ${playerMoveString} and tied ${opponentMoveString}!`}
            </div>
          )
        }
        setMessage(() => newMessage)
      }

      const isPlayerWinner = playerID === winningGamePlayer

      if (isPlayerWinner) {
        const newMessage = function () {
          return enabled ? (
            <div>{`You Win! You played ${playerMoveString} and beat ${opponentMoveString}. You received 10 tickets!`}</div>
          ) : (
            <div>
              {`For each win, the game deposits 10 tickets in the form of Fungible
            Tokens into an in-app custodial Flow account. `}
              <a
                className="text-blue-600"
                href={`https://${process.env.NEXT_PUBLIC_FLOWVIEW_NETWORK}.flowview.app/account/${gameAccountAddress}/fungible_token`}
                target="_blank"
                rel="noreferrer"
              >
                {`View account ${gameAccountAddress} on flowview`}
              </a>
              {`). Head to settings and connect a wallet to link
            this account. Once linked you'll have full control over the tickets
            and other assets held here. `}
            </div>
          )
        }
        setMessage(() => newMessage)
      } else if (winningNFTID && !isPlayerWinner) {
        const newMessage = function () {
          return (
            <div>
              {`You played ${playerMoveString} and lost against ${opponentMoveString}!`}
            </div>
          )
        }
        setMessage(() => newMessage)
      }
    },
    [enabled, gameAccountAddress, gamePieceNFTID, gamePlayerID]
  )

  useEffect(() => {
    if (gameStatus === GameStatus.ENDED) {
      handleEndgame(gameResult)
    }
    if (gameStatus === GameStatus.READY) {
      if (purchaseSuccessModalOpen && !gameMatchID && enabled) {
        handlePlay()
      }
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
          {!playerMove &&
            (gameStatus === GameStatus.READY ||
              gameStatus === GameStatus.PLAYING) && (
              <span className="text-9xl font-extrabold">❓</span>
            )}
        </div>

        <div className="flex min-h-full items-center justify-center">
          <div className="m-4 flex min-h-full flex-col items-center justify-center">
            <Image
              width={200}
              height={200}
              alt="user monster"
              src={MonsterLogo.src}
              className="tile flex h-24 w-24 items-center justify-center bg-green-500"
            />
            <code className="mt-4">You</code>
          </div>

          <code className="m-4">{'vs'}</code>

          <div className="m-4 flex min-h-full flex-col items-center justify-center">
            <Image
              width={200}
              height={200}
              alt="opponent monster"
              src={MarketLogo.src}
              className="tile flex h-24 w-24 items-center justify-center bg-pink-500"
            />
            <code className="mt-4">Opponent</code>
          </div>
        </div>

        <div className="flex h-60 items-center justify-center rounded-md border border-pink-500 border-opacity-100 md:h-96">
          {loadingOpponentMove && <Spinner size={70} />}
          {opponentMove === 'rock' && (
            <span className="text-9xl font-extrabold">🪨</span>
          )}
          {opponentMove === 'paper' && (
            <span className="text-9xl font-extrabold">📄</span>
          )}
          {opponentMove === 'scissors' && (
            <span className="text-9xl font-extrabold">✂️</span>
          )}
          {!playerMove &&
            !loadingOpponentMove &&
            (gameStatus === GameStatus.READY ||
              gameStatus === GameStatus.PLAYING) && (
              <span className="text-9xl font-extrabold">❓</span>
            )}
        </div>
      </div>

      <Row>
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
      </Row>
      <div className="mt-12 flex w-full flex-row items-center justify-center md:mt-24">
        <div className="flex w-full items-center justify-center space-x-4 text-2xl font-extrabold text-green-500">
          <span> Wins: {winLossRecord?.wins ?? 0}</span>
          <span> Losses: {winLossRecord?.losses ?? 0}</span>
          <span> Ties: {winLossRecord?.ties ?? 0}</span>
        </div>
      </div>
      <Modal
        isOpen={goToMarketplaceModalOpen && !fullScreenLoading && !enabled}
        handleClose={() => setGoToMarketplaceOpen(false)}
        title={"What's Happening?"}
        DialogContent={() => (
          <div>
            {`When you connected your wallet, the in-app custodial Flow account
            delegated control to your wallet, establishing hybrid custody of
            your NFTs and FTs while they continue to reside in the in-app
            custodial Flow account. `}
            <a
              className="text-blue-600"
              href={`https://${process.env.NEXT_PUBLIC_FLOWVIEW_NETWORK}.flowview.app/account/${gameAccountAddress}`}
              target="_blank"
              rel="noreferrer"
            >
              {`View account ${gameAccountAddress} on flowview`}
            </a>
            {'.'}
          </div>
        )}
        buttonText={'Go to Marketplace'}
        buttonFunc={() => {
          window.open(process.env.NEXT_PUBLIC_MARKETPLACE_URL || '')
        }}
      />
      <Modal
        isOpen={purchaseSuccessModalOpen && !gameMatchID && !enabled}
        handleClose={
          gameStatus === GameStatus.READY
            ? handlePlay
            : () => setPurchaseSuccessModalOpen(false)
        }
        title={"What's Happening?"}
        DialogContent={() => (
          <div>
            {`After submitting your payment, a game piece NFT was minted and
            deposited into the in-app custodial Flow account . `}
            <a
              className="text-blue-600"
              href={`https://${process.env.NEXT_PUBLIC_FLOWVIEW_NETWORK}.flowview.app/account/${gameAccountAddress}/storage/GamePieceNFTCollection`}
              target="_blank"
              rel="noreferrer"
            >
              {`View account ${gameAccountAddress} on flowview`}
            </a>
            {`. You can use this NFT to play the game and win tickets.`}
          </div>
        )}
        buttonText={'Play Now!'}
        buttonFunc={
          gameStatus === GameStatus.READY
            ? handlePlay
            : () => setPurchaseSuccessModalOpen(false)
        }
      />
      <Modal
        isOpen={playModalOpen && !enabled}
        handleClose={
          gameStatus === GameStatus.ENDED
            ? handlePlayAgain
            : () => setPlayModalOpen(false)
        }
        title={'Good Game!'}
        DialogContent={message ?? ''}
        buttonText={'Play Again!'}
        buttonFunc={
          gameStatus === GameStatus.ENDED
            ? handlePlayAgain
            : () => setPlayModalOpen(false)
        }
      />
    </div>
  )
}

export default GameView
