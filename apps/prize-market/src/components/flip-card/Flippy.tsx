import React, {
  forwardRef,
  useEffect,
  useImperativeHandle,
  useRef,
  useState,
} from 'react'

interface FlippyProps {
  isFlipped?: boolean
  className?: string
  flipDirection?: string
  style?: object
  children?: React.ReactNode
  flipOnHover?: boolean
  flipOnClick?: boolean
  onClick?: (event: React.MouseEvent<HTMLDivElement, MouseEvent>) => void
  onTouchStart?: (event: React.TouchEvent<HTMLDivElement>) => void
  onMouseEnter?: (event: React.MouseEvent<HTMLDivElement, MouseEvent>) => void
  onMouseLeave?: (event: React.MouseEvent<HTMLDivElement, MouseEvent>) => void
}

type Ref = HTMLDivElement | { toggle: () => void }

export const Flippy = forwardRef<Ref, FlippyProps>(function Flippy(
  {
    isFlipped: _isFlipped,
    className,
    flipDirection = 'horizontal',
    style,
    children,
    flipOnHover,
    flipOnClick,
    onClick,
    onTouchStart,
    onMouseEnter,
    onMouseLeave,
  },
  ref
) {
  const simpleFlag = useRef({ isTouchDevice: false })
  const [isTouchDevice, setTouchDevice] = useState(false)
  const [isFlipped, setFlipped] = useState(false)
  const toggle = () => setFlipped(!isFlipped)

  useImperativeHandle(ref, () => ({ toggle }))

  const handleTouchStart = (event: React.TouchEvent<HTMLDivElement>) => {
    if (!isTouchDevice) {
      simpleFlag.current.isTouchDevice = true
      setTouchDevice(true)
    }
    onTouchStart?.(event)
  }

  const handleMouseEnter = (
    event: React.MouseEvent<HTMLDivElement, MouseEvent>
  ) => {
    if (flipOnHover && !simpleFlag.current.isTouchDevice) {
      setFlipped(true)
    }
    onMouseEnter?.(event)
  }

  const handleMouseLeave = (
    event: React.MouseEvent<HTMLDivElement, MouseEvent>
  ) => {
    if (flipOnHover && !simpleFlag.current.isTouchDevice) {
      setFlipped(false)
    }
    onMouseLeave?.(event)
  }

  const handleClick = (event: React.MouseEvent<HTMLDivElement, MouseEvent>) => {
    switch (true) {
      case flipOnHover && !simpleFlag.current.isTouchDevice:
      case !flipOnClick && !flipOnHover:
        break
      default:
        setFlipped(!isFlipped)
        break
    }
    onClick?.(event)
  }

  useEffect(() => {
    if (typeof _isFlipped === 'boolean' && _isFlipped !== isFlipped) {
      setFlipped(_isFlipped)
    }
  }, [_isFlipped, isFlipped])

  return (
    <div
      className={`flippy-container ${className || ''}`}
      style={{
        ...style,
      }}
      onTouchStart={handleTouchStart}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      onClick={handleClick}
    >
      <div className={`flippy-cardContainer-wrapper ${flipDirection}`}>
        <div
          className={`flippy-cardContainer ${isFlipped ? 'isActive' : ''} ${
            isTouchDevice ? 'istouchdevice' : ''
          }`}
          data-testid="flippy-card"
        >
          {children}
        </div>
      </div>
    </div>
  )
})

export default Flippy
