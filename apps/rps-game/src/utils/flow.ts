import * as fcl from '@onflow/fcl'
import { template as createAccountSIX } from '@onflow/six-create-account'
import { adminAuthorizationFunction } from './authz-functions'

export async function createAccount(publicKeyHex: string): Promise<string> {
  const txId = await fcl.decode(
    await fcl.send([
      createAccountSIX({
        proposer: adminAuthorizationFunction,
        authorization: adminAuthorizationFunction,
        payer: adminAuthorizationFunction,
        publicKey: publicKeyHex,
        signatureAlgorithm: 1,
        hashAlgorithm: 3,
        weight: '1000.0',
      }),
    ])
  )

  return new Promise((res, rej) => {
    fcl.tx(txId).subscribe((txStatus: any) => {
      if (txStatus.status === 4) {
        const accountCreatedEvent = txStatus.events.find(
          (event: any) => event.type === 'flow.AccountCreated'
        )
        if (!accountCreatedEvent) return
        const accountCreatedEventData = accountCreatedEvent.data
        const accountCreatedAddress = accountCreatedEventData.address
        res(accountCreatedAddress)
      } else if (txStatus.status === 5) {
        rej('Error creating account')
      }
    })
  })
}
