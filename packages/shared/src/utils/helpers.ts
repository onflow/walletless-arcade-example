export const cls = (input: string) =>
  input
    .replace(/\s+/gm, ' ')
    .split(' ')
    .filter(cond => typeof cond === 'string')
    .join(' ')
    .trim()

export const styles = {
  container:
    'my-4 lg:my-10 p-2 bg-gray-200 rounded-md shadow-inner md:container md:mx-auto',
  li: 'rounded-md border border-gray-300 p-3 text-blue-900 bg-blue-200',
}
