export function getUrl() {
  return process.env.VERCEL_URL
    ? process.env.VERCEL_URL
    : 'http://localhost:' + process.env.NEXT_PUBLIC_PORT
}
