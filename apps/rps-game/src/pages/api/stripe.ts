import type { NextApiRequest, NextApiResponse } from 'next'
import Stripe from 'stripe'
import { getUrl } from '../../utils/get-url'

const stripe = new Stripe(process.env.STRIPE_SK as string, {
  apiVersion: '2022-11-15',
})

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse<any>
) {
  if (req.method !== 'POST') {
    res.status(405).send({ message: 'Only POST requests allowed' })
    return
  }

  const session = await stripe.checkout.sessions.create({
    line_items: [
      {
        // Provide the exact Price ID (for example, pr_1234) of the product you want to sell
        price: 'price_1MUHQfDBqJxytuDJzhrJPVdZ',
        quantity: 1,
      },
    ],
    mode: 'payment',
    success_url: `${getUrl()}?purchase_success=true`,
    cancel_url: `${getUrl()}?purchase_error=true`,
  })

  res.json({ url: session.url })
  res.end()
}
