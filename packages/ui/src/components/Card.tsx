export const Card = ({
  title,
  cta = '',
  href,
}: {
  title: string
  cta?: string
  href: string
}) => {
  return (
    <div className="group h-full rounded-lg border border-transparent bg-zinc-400 p-4">
      <p className="inline-block text-xl text-white">{title}</p>
      <div className="mt-4 text-xs group-hover:underline">{cta} →</div>
    </div>
  )
}
