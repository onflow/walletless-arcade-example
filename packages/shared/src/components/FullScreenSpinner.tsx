import { FaSpinner } from 'react-icons/fa'

export const FullScreenSpinner = ({
  display = false,
  message = 'Transaction submitted...',
}: {
  display: boolean
  message?: string
}) => {
  return (
    <div
      className={`${
        display ? '' : 'hidden'
      } fixed top-0 left-0 right-0 bottom-0 z-50 flex h-screen w-full flex-col items-center justify-center overflow-hidden bg-gray-700 opacity-75`}
    >
      <span className="mb-4 text-center text-xl font-semibold text-green-500 opacity-75">
        <FaSpinner className="spinner" size={70} />
      </span>
      <h2 className="text-center text-xl font-bold text-green-500">
        Loading...
      </h2>
      <p className="w-1/3 text-center text-green-500">{message}</p>
    </div>
  )
}

export default FullScreenSpinner
