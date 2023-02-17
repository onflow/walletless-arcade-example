import { FaSpinner } from 'react-icons/fa'

export const Spinner = ({ show = false }: { show: boolean }) => {
  return (
    <div
      className={`fixed top-0 left-0 z-50 block ${
        show ? '' : 'hidden'
      } h-full w-full bg-white opacity-75`}
    >
      <span className="relative top-1/2 my-0 mx-auto block h-0 w-0 text-green-500 opacity-75">
        <FaSpinner className="spinner" size={70} />
      </span>
    </div>
  )
}

export default Spinner
