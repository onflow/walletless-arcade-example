import { type NextApiRequest, type NextApiResponse } from 'next'

import { generateKeys, sign } from '../../../utils/crypto'

const adminAuthorization = async (
  req: NextApiRequest,
  res: NextApiResponse
) => {
  if (req.method !== 'POST') {
    res.status(405).send({ message: 'Only POST requests allowed' })
    return
  }
  const body = req.body

  const message = body.message
  const privateKey = process.env.ADMIN_PRIVATE_KEY_HEX as string

  const signature = await sign(message, privateKey)

  res.status(200).json(signature)
}

export default adminAuthorization
