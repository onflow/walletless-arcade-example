type FooterProps = {
  src?: string
  title?: string
  text?: string
}
export default function LinkCard({
  src = '#',
  title = 'title',
  text = 'description',
}: FooterProps) {
  return (
    <a
      href={src}
      className="w-96 rounded-xl border-2 border-rose-500 p-6 text-left hover:text-blue-600 focus:text-blue-600"
    >
      <h3 className="text-2xl font-bold">{title}</h3>
      <p className="mt-4 text-xl">{text}</p>
    </a>
  )
}
