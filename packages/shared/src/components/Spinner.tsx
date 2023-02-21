import { FaSpinner } from 'react-icons/fa'

export const Spinner = ({ size = 70 }: { size: number }) => {
  return (
    <span className="text-green-500 opacity-75">
      <FaSpinner className="spinner" size={size} />
    </span>
  )
}

export default Spinner
