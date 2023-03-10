import type { StaticImageData } from 'next/image'
import Image from 'next/image'
import type { ReactNode } from 'react'
import BackSide from './BackSide'
import FrontSide from './FrontSide'

interface IProps {
  children?: ReactNode
  image: string | StaticImageData,
  cardTitle: string,
  cardBackContents: string
}

const DefaultCardContents = ({ children, image, cardTitle, cardBackContents }: IProps) => (
  <>
    <FrontSide
      style={{
        backgroundColor: '#41669d',
        display: 'flex',
        alignItems: 'center',
        flexDirection: 'column',
        padding: '20px',
      }}
      cardType="front"
    >
      <Image
        src={image}
        priority
        alt="Image of a Doodle NFT"
        width={400}
        height={400}
        sizes="100vw"
        style={{ maxWidth: '100%', maxHeight: '100%' }}
      />
      <div className="mt-2">{cardTitle}</div>

      <span
        style={{
          fontSize: '12px',
          position: 'absolute',
          bottom: '10px',
          width: '100%',
        }}
      >
        {children}
      </span>
    </FrontSide>
    <BackSide
      style={{
        backgroundColor: '#93C5FD',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexDirection: 'column',
        padding: '20px',
      }}
      cardType="back"
    >
      {cardBackContents}
      <span className="mt-12">
        <svg
          width="41"
          height="41"
          viewBox="0 0 41 41"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <circle cx="20.5" cy="20.5" r="20.5" fill="#00EF8B" />
          <rect
            x="23.71"
            y="17.2898"
            width="5.7892"
            height="5.7892"
            fill="white"
          />
          <path
            d="M17.9216 25.2479C17.9232 26.1275 17.3944 26.9214 16.582 27.2588C15.7697 27.5962 14.834 27.4105 14.212 26.7885C13.59 26.1665 13.4044 25.2309 13.7418 24.4185C14.0792 23.6062 14.873 23.0773 15.7527 23.079H17.9216V17.2898H15.7527C12.5315 17.2881 9.62669 19.2275 8.39324 22.2031C7.15979 25.1787 7.84074 28.6044 10.1184 30.8821C12.3961 33.1598 15.8218 33.8408 18.7975 32.6073C21.7731 31.3739 23.7124 28.4691 23.7108 25.2479V23.079H17.9216V25.2479Z"
            fill="white"
          />
          <path
            d="M25.879 14.395H32.3898V8.60986H25.879C21.4857 8.61438 17.9254 12.1747 17.9209 16.568V17.2896H23.7101V16.568C23.7123 15.3704 24.6814 14.3995 25.879 14.395Z"
            fill="white"
          />
          <path
            d="M17.9209 23.079H23.7101V17.2898H17.9209V23.079Z"
            fill="#16FF99"
          />
        </svg>
      </span>
      <span
        style={{
          fontSize: '12px',
          position: 'absolute',
          bottom: '10px',
          width: '100%',
        }}
      >
        {children}
      </span>
    </BackSide>
  </>
)

export default DefaultCardContents
