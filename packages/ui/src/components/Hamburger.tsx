type HamburgerProps = {
  onClick: () => void
}

export default function Hamburger({ onClick }: HamburgerProps) {
  return (
    <div className="mt-1 mt-8 flex flex-1 justify-end p-2 lg:hidden">
      <button
        className="text-primary-black flex items-center rounded border px-3 py-2 text-lg hover:opacity-75"
        onClick={onClick}
      >
        <svg
          className="h-6 w-6 fill-current"
          viewBox="0 0 20 20"
          xmlns="http://www.w3.org/2000/svg"
        >
          <title>Menu</title>
          <path d="M0 3h20v2H0V3zm0 6h20v2H0V9zm0 6h20v2H0v-2z" />
        </svg>
      </button>
    </div>
  )
}
