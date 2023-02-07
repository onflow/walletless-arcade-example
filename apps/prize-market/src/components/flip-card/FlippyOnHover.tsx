import Flippy from './Flippy'
import DefaultCardContents from './DefaultCardContents'
import Prize from '../../../public/static/rainbowduck.png'

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
}: {
  flipDirection: string
}) => (
  <Flippy flipOnHover={true} flipDirection={flipDirection} style={FlippyStyle}>
    <DefaultCardContents image={Prize}>10 Tickets</DefaultCardContents>
  </Flippy>
)

export default FlippyOnHover
