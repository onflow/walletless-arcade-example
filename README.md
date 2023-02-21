# Flow Game Arcade and Prize Marketplace Demo

<p align="center">
<br />
<a href="https://github.com/onflow/walletless-arcade-example#quickstart-demo">Quickstart</a>
·
<a href="https://github.com/onflow/fcl-js/blob/master/CONTRIBUTING.md">Contribute</a>

</p>

> :warning: This repo is a WIP aiming to showcase how Auth Account capabilities from [FLIP 53](https://github.com/onflow/flips/pull/53) could be use to achieve hydrid custody

This is example Flow App was created to demonstrate walletless onboarding and promote composable, secure, and smooth UX for on-chain games without the need for a traditional backend. It uses an on-chain Rock Paper Scissors game and NFT "Marketplace" as a proof of concept exploration into the world of blockchain gaming and hybrid custody powered by Cadence on Flow.

## Learn More

- [Account Linking Overview](https://developers.flow.com/account-linking)
- [Explore Walletless Onboarding](https://developers.flow.com/account-linking/guides/walletless-onboarding)
- [Hybrid Custody](https://forum.onflow.org/t/hybrid-custody/4016)
- [Child Account Contract](https://f.dnz.dev/0x1b655847a90e644a/ChildAccount)

### Apps and Packages

- `rps-game`: a [Next.js](https://nextjs.org/) app for the Monster Game Arcade (Rock, Paper, Scissors)
- `prize-market`: a [Next.js](https://nextjs.org/) app for the Monster Mall Prize Marketplace
- `shared`: React components and Contexts shared by both `rps-game` and `prize-market` applications
- `eslint-config-custom`: `eslint` configurations (includes `eslint-config-next` and `eslint-config-prettier`)
- `tsconfig`: `tsconfig.json`s used throughout the monorepo
- `tailwind-config`: shared `tailwind.config.js` used throughout the monorepo

## Quickstart Demo

To demo the functionality of this repo, clone it and follow the steps below.

### Pre-Requisites

1. Install Flow CLI 
:warning: Requires installation of [Flow CLI](https://github.com/onflow/flow-cli/releases/tag/v0.45.1-cadence-attachments-3) (Attachments/AuthAccount Capability pre-release version).

```sh
sh -ci "$(curl -fsSL https://raw.githubusercontent.com/onflow/flow-cli/master/install.sh)" -- v0.45.1-cadence-attachments-3
```

2. Copy `emulator.private.json.example` and `testnet.private.json.example` files and update with your own key data.

```sh
cp emulator.private.json.example emulator.private.json
cp testnet.private.json.example testnet.private.json
```

3. Copy the .env-example file to .env and update the required values.

```sh
cp .env-example .env
```

:warning: App requires several `env` vars for development and deployment. Credentials and API keys can be acquired through their respective providers. See `.env-example` for details

#### Service Providers

- Stripe (Used for NFT Purchase): [https://stripe.com/docs/development](https://stripe.com/docs/development)
- Google (Used as Next Auth Provider): [https://developers.google.com/identity/protocols/oauth2/openid-connect](https://developers.google.com/identity/protocols/oauth2/openid-connect)

### Run Demo

- Start the emulator

```sh
flow emulator start
```

- Start the Dev Wallet

```sh
flow dev-wallet
```


- Start dev server to deploy the contracts and configure the service account

```sh
npm run dev:local:deploy
```

This command will start the dev server and deploy the contracts to the emulator. It will also configure the service account with the required capabilities.

### Develop

To develop all apps and packages, run the following command:

```shell
npm run dev
```

### Add packages

To add packages to a specify workspace, run the following command:

```shell
npm install -D react --workspace=shared
```

### Build

To build all apps and packages, run the following command:

```shell
npm run build
```

### Deploy
The following env vars are required for deployment:
#### Public
- NEXT_PUBLIC_VERCEL_URL: Your Vercel URL (ex: https://walletless-arcade-game.vercel.app)
- NEXT_PUBLIC_ADMIN_ADDRESS: The address of the admin account where game and prize contracts are deployed
- NEXT_PUBLIC_ADMIN_KEY_INDEX: The key index of the admin account where game and prize contracts are deployed
- NEXTAUTH_URL: Your Vercel URL (ex: https://walletless-arcade-game.vercel.app)
- NEXTAUTH_SECRET: A random string is used to hash tokens, sign/encrypt cookies and generate cryptographic keys. You can generate the secret via `openssl rand -base64 32` on Linux
- NEXT_PUBLIC_FLOW_NETWORK: The network you are deploying to (ex: testnet)
- NEXT_PUBLIC_MARKETPLACE_URL: The URL of the prize marketplace (ex: https://walletless-arcade-prize-market.vercel.app)
#### Private
- ADMIN_PRIVATE_KEY_HEX: The private key of the admin account where game and prize contracts are deployed
- GOOGLE_CLIENT_SECRET: The Google Client Secret. Used as Provider for NextAuth
- GOOGLE_CLIENT_ID: The Google Client ID. Used as Provider for NextAuth
- STRIPE_SK: The Stripe Secret Key. Used for NFT Purchase
