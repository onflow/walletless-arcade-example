import { type NextApiRequest, type NextApiResponse } from 'next'
import { generateKeys } from '../../../utils/crypto'
import { createAccount as createAccountUtil } from '../../../utils/flow'
import { loadFCLConfig } from '../../../utils/fcl-setup'
loadFCLConfig()

const createAccount = async (req: NextApiRequest, res: NextApiResponse) => {
  if (req.method !== 'POST') {
    res.status(405).send({ message: 'Only POST requests allowed' })
    return
  }

  const keys = await generateKeys()
  const address = await createAccountUtil(keys.publicKey)

  res.status(200).json({
    publicKey: keys.publicKey,
    privateKey: keys.privateKey,
    address,
  })
}

export default createAccount
