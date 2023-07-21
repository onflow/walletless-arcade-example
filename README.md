# Flow Game Arcade and Prize Marketplace Demo

<p align="center">
<br />
<a href="https://github.com/onflow/walletless-arcade-example#quickstart-demo">Quickstart</a>
·
<a href="https://github.com/onflow/fcl-js/blob/master/CONTRIBUTING.md">Contribute</a>

</p>

This is example Flow App was created to demonstrate walletless onboarding and promote composable, secure, and smooth UX for on-chain games without the need for a traditional backend. It uses an on-chain Rock Paper Scissors game and NFT "Marketplace" as a proof of concept exploration into the world of blockchain gaming and hybrid custody powered by Cadence on Flow.

**IMPORTANT**

> **Warning**
>
> :warning: This project implements a local key management solution, but should **not** be used as a reference for
> building a production grade application.
>
> This project should only be used in aid of local development against a locally run instance of the Flow blockchain like the Flow emulator, and should never be used in conjunction with Flow Mainnet, Testnet, Canarynet or any other instances of Flow.

## Learn More

- [Account Linking Overview](https://developers.flow.com/account-linking)
- [Explore Walletless Onboarding](https://developers.flow.com/account-linking/guides/walletless-onboarding)
- [Hybrid Custody Intro Forum Post](https://forum.onflow.org/t/hybrid-custody/4016)
- [HybridCustody Contract](https://f.dnz.dev/294e44e1ec6993c6/HybridCustody)
- [HybridCustody Source Repo](https://github.com/onflow/hybrid-custody)

### Apps and Packages

- `rps-game`: a [Next.js](https://nextjs.org/) app for the Monster Game Arcade (Rock, Paper, Scissors)
- `prize-market`: a [Next.js](https://nextjs.org/) app for the Monster Mall Prize Marketplace
- `shared`: React components and Contexts shared by both `rps-game` and `prize-market` applications
- `eslint-config-custom`: `eslint` configurations (includes `eslint-config-next` and `eslint-config-prettier`)
- `tsconfig`: `tsconfig.json`s used throughout the monorepo
- `tailwind-config`: shared `tailwind.config.js` used throughout the monorepo

## Quickstart Demo

To demo the functionality of this repo, clone it and follow the steps below.

```sh
git clone https://github.com/onflow/walletless-arcade-example

cd walletless-arcade-example
```

### Pre-Requisites

**1. Install Flow CLI**

Follow [installation instructions](https://developers.flow.com/tooling/flow-cli/install) to install Flow CLI on to your machine.

**2. Copy `emulator.private.json.example` and `testnet.private.json.example`**

```sh
cp emulator.private.json.example emulator.private.json
cp testnet.private.json.example testnet.private.json
```

:bookmark: Update with your own key data.

**3. Copy the .env-example file to .env and update the required values.**

```sh
cp .env-example .env
```

:warning: App requires several `env` vars for development and deployment. Credentials and API keys can be acquired through their respective providers. See `.env-example` for details

#### Service Providers

- Stripe (Used for NFT Purchase): [https://stripe.com/docs/development](https://stripe.com/docs/development)
- Google (Used as Next Auth Provider): [https://developers.google.com/identity/protocols/oauth2/openid-connect](https://developers.google.com/identity/protocols/oauth2/openid-connect)

### Run Demo Locally

- Start the emulator

```sh
flow emulator start
```

- Start the Dev Wallet (From a new terminal window)

```sh
flow dev-wallet
```

- Start dev server to deploy the contracts and configure the service account (From a new terminal window) - this will create our emulator deployment accounts, transfer our dev account some $FLOW, and configure initial resources

```sh
npm run dev:local:complete
```

This command will start the dev server and deploy the contracts to the emulator. It will also configure the service account with the required capabilities.

### Deployment

Refer to `testnet-account` deployment from `flow.json` to deploy required contracts to your own game admin account.
This account will need a Flow balance for use in account creation and transaction fees.

Once contracts are deployed to your admin accounts, update the `NEXT_PUBLIC_ADMIN_ADDRESS` and `NEXT_PUBLIC_ADMIN_KEY_INDEX` env vars in your on your deployment platform.

Run the following transaction to configure the admin account with the required capabilities:

```shell
flow transactions send --network=testnet --signer testnet-account cadence/transactions/child_account/setup_child_account_creator.cdc
```

#### Environment variables and Configuration
The following env vars are required for deployment:
**Public**
- `NEXT_PUBLIC_VERCEL_URL`: Your Vercel URL (ex: https://walletless-arcade-game.vercel.app)
- `NEXT_PUBLIC_ADMIN_ADDRESS`: The address of the admin account where game and prize contracts are deployed
- `NEXT_PUBLIC_ADMIN_KEY_INDEX`: The key index of the admin account where game and prize contracts are deployed
- `NEXTAUTH_URL`: Your Vercel URL (ex: https://walletless-arcade-game.vercel.app)
- `NEXTAUTH_SECRET`: A random string is used to hash tokens, sign/encrypt cookies and generate cryptographic keys. You can generate the secret via `openssl rand -base64 32` on Linux
- `NEXT_PUBLIC_FLOW_NETWORK`: The network you are deploying to (ex: testnet)
- `NEXT_PUBLIC_MARKETPLACE_URL`: The URL of the prize marketplace (ex: https://walletless-arcade-prize-market.vercel.app)

**Private**
- `ADMIN_PRIVATE_KEY_HEX`: The private key of the admin account where game and prize contracts are deployed
- `GOOGLE_CLIENT_SECRET`: The Google Client Secret. Used as Provider for NextAuth
- `GOOGLE_CLIENT_ID`: The Google Client ID. Used as Provider for NextAuth
- `STRIPE_SK`: The Stripe Secret Key. Used for NFT Purchase
