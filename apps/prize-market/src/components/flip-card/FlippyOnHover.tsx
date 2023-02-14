import Flippy from './Flippy'
import DefaultCardContents from './DefaultCardContents'
import Prize from '../../../public/static/rainbowduck.png'
import { StaticImageData } from 'next/image'

const FlippyStyle = {
  width: '200px',
  height: '300px',
  textAlign: 'center',
  color: '#FFF',
  fontFamily: 'sans-serif',
  fontSize: '1.25em',
  justifyContent: 'center',
}

const FlippyOnHover = ({
  flipDirection = 'vertical',
  image = Prize,
  cardTitle = "Rainbow Duck",
  cardContents = "10 Tickets",
  cardBackContents = "The happiest rainbow duck friend, prized for its vibrant feathers!"
}: {
  flipDirection?: string,
  image?: string | StaticImageData,
  cardTitle?: string,
  cardContents?: string,
  cardBackContents?: string,
}) => (
  <Flippy flipOnHover={true} flipDirection={flipDirection} style={FlippyStyle}>
    <DefaultCardContents image={image} cardTitle={cardTitle} cardBackContents={cardBackContents}>{cardContents}</DefaultCardContents>
  </Flippy>
)

export default FlippyOnHover
