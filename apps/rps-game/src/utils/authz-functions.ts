import { sign } from './crypto'
import type { AuthorizationObject } from '@onflow/fcl'
import { getUrl } from './get-url'

// export function adminAuthorizationFunction(account: any) {
//   const adminPrivateKey = env.NEXT_PUBLIC_ADMIN_PRIVATE_KEY_ID;
//   const adminKeyIndex = env.NEXT_PUBLIC_ADMIN_PRIVATE_KEY_ID;
//   const adminAddress = env.NEXT_PUBLIC_ADMIN_ADDRESS;

//   // authorization function need to return an account
//   return {
//     ...account, // bunch of defaults in here, we want to overload some of them though
//     tempId: `${adminAddress}-${adminKeyIndex}`, // tempIds are more of an advanced topic, for 99% of the times where you know the address and keyId you will want it to be a unique string per that address and keyId
//     addr: adminAddress, // the address of the signatory
//     keyId: Number(adminKeyIndex), // this is the keyId for the accounts registered key that will be used to sign, make extra sure this is a number and not a string
//     signingFunction: async (signable: any) => {
//       // Singing functions are passed a signable and need to return a composite signature
//       // signable.message is a hex string of what needs to be signed.
//       return {
//         addr: adminAddress, // needs to be the same as the account.addr
//         keyId: Number(adminKeyIndex), // needs to be the same as account.keyId, once again make sure its a number and not a string
//         signature: await sign(signable.message, adminPrivateKey), // this needs to be a hex string of the signature, where signable.message is the hex value that needs to be signed
//       };
//     },
//   };
// }

export function adminAuthorizationFunction(account: any): AuthorizationObject {
  const address = process.env.NEXT_PUBLIC_ADMIN_ADDRESS
  const keyIndex = process.env.NEXT_PUBLIC_ADMIN_KEY_INDEX
  return {
    ...account, // bunch of defaults in here, we want to overload some of them though
    tempId: `${address}-${keyIndex}`, // tempIds are more of an advanced topic, for 99% of the times where you know the address and keyId you will want it to be a unique string per that address and keyId
    addr: address, // the address of the signatory
    keyId: Number(keyIndex), // this is the keyId for the accounts registered key that will be used to sign, make extra sure this is a number and not a string
    signingFunction: async (signable: any) => {
      // Singing functions are passed a signable and need to return a composite signature
      // signable.message is a hex string of what needs to be signed.

      const signature = await fetch(`${getUrl()}/api/authz/admin`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: signable.message,
        }),
      }).then(res => res.json())

      return {
        addr: address, // needs to be the same as the account.addr
        keyId: Number(keyIndex), // needs to be the same as account.keyId, once again make sure its a number and not a string
        // signature: await sign(signable.message, privateKey), // this needs to be a hex string of the signature, where signable.message is the hex value that needs to be signed
        signature,
      }
    },
  }
}

export function userAuthorizationFunction(
  privateKey: string,
  keyIndex: string,
  address: string
) {
  return async function (account: any) {
    // authorization function need to return an account

    return {
      ...account, // bunch of defaults in here, we want to overload some of them though
      tempId: `${address}-${keyIndex}`, // tempIds are more of an advanced topic, for 99% of the times where you know the address and keyId you will want it to be a unique string per that address and keyId
      addr: address, // the address of the signatory
      keyId: Number(keyIndex), // this is the keyId for the accounts registered key that will be used to sign, make extra sure this is a number and not a string
      signingFunction: async (signable: any) => {
        // Singing functions are passed a signable and need to return a composite signature
        // signable.message is a hex string of what needs to be signed.

        const signature = await fetch(`${getUrl()}/api/authz/user`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            privateKey,
            message: signable.message,
          }),
        }).then(res => res.json())

        return {
          addr: address, // needs to be the same as the account.addr
          keyId: Number(keyIndex), // needs to be the same as account.keyId, once again make sure its a number and not a string
          // signature: await sign(signable.message, privateKey), // this needs to be a hex string of the signature, where signable.message is the hex value that needs to be signed
          signature,
        }
      },
    }
  }
}
