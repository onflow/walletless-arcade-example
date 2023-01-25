import type { NextApiRequest, NextApiResponse } from 'next'

const stripe = require('stripe')(process.env.STRIPE_SK)

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
    success_url: `http://localhost:3002?purchase_success=true`,
    cancel_url: `http://localhost:3002?purchase_error=true`,
  })

  res.json({ url: session.url })
  res.end()
}
