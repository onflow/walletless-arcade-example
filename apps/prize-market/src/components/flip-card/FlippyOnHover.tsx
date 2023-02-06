import Flippy from './Flippy'
import DefaultCardContents from './DefaultCardContents'
import Dood from '../../../public/static/rainbow-dood.png'

const FlippyStyle = {
  width: '200px',
  height: '300px',
  textAlign: 'center',
  color: '#FFF',
  fontFamily: 'sans-serif',
  fontSize: '30px',
  justifyContent: 'center',
}

const FlippyOnHover = ({
  flipDirection = 'vertical',
  imageSrc,
}: {
  flipDirection: string
  imageSrc: string
}) => (
  <Flippy flipOnHover={true} flipDirection={flipDirection} style={FlippyStyle}>
    <DefaultCardContents imageSrc={imageSrc} image={Dood} />
  </Flippy>
)

export default FlippyOnHover
