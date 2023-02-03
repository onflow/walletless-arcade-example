import { type NextApiRequest, type NextApiResponse } from 'next'
import * as fcl from "@onflow/fcl";
import { adminAuthorizationFunction } from "../../../utils/authz-functions";
import MINT_TOKENS from "../../../../cadence/transactions/ticket-token/mint-tokens"
import { loadFCLConfig  } from '../../../utils/fcl-setup';
loadFCLConfig()

export async function mintTicketHelper(destinationAddress: string, amount: string): Promise<void> {
  const txId = 
    await fcl.mutate({
      cadence: MINT_TOKENS,
      proposer: adminAuthorizationFunction,
      authorizations: [adminAuthorizationFunction],
      payer: adminAuthorizationFunction,
      args: (arg, t) => [
        arg(fcl.withPrefix(destinationAddress), t.Address),
        arg(amount, t.UFix64)
      ],
      limit: 9999
    })

  return new Promise((res, rej) => {
    fcl.tx(txId).subscribe((txStatus: any) => {
      if (txStatus.status === 4) {
        res();
      } else if (txStatus.status === 5) {
        rej("Error creating account");
      }
    });
  });
}

const mintTickets = async (req: NextApiRequest, res: NextApiResponse) => {
  if (req.method !== 'POST') {
    res.status(405).send({ message: 'Only POST requests allowed' })
    return
  }

  const body = JSON.parse(req.body)

  const destinationAddress = body?.destinationAddress
  const amount = body?.amount
  
  try {
    await mintTicketHelper(destinationAddress, amount)  

    res.status(200)
    res.end()
  } catch (e) {
    res.status(500)
    res.end()
  }
}

export default mintTickets
 