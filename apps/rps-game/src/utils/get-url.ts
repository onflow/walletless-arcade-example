export function getUrl() {
  return process.env.NEXT_PUBLIC_VERCEL_URL
    ? process.env.NEXT_PUBLIC_VERCEL_URL
    : 'http://localhost:' + process.env.NEXT_PUBLIC_PORT
}
