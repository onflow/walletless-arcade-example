type ButtonProps = {
  children?: string
  onClick?: () => void
}

export const Button = ({
  onClick = () => {},
  children = 'Button',
}: ButtonProps) => {
  return (
    <button
      onClick={onClick}
      className="cursor-pointer rounded-md bg-black py-4 px-6 text-sm text-white hover:bg-gray-100 hover:text-black"
    >
      {children}
    </button>
  )
}
