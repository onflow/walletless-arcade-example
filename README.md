# Flow Game Arcade and Prize Marketplace Demo

This is example Flow App was created to demonstrate walletless onboarding and promote composable, secure, and smooth UX for on-chain games without the need for a traditional backend.

### Apps and Packages

- `rps-game`: a [Next.js](https://nextjs.org/) app for the Monster Game Arcade (Rock, Paper, Scissors)
- `prize-market`: a [Next.js](https://nextjs.org/) app for the Monster Mall Prize Marketplace
- `ui`: a stub React component library shared by both `rps-game` and `prize-market` applications
- `eslint-config-custom`: `eslint` configurations (includes `eslint-config-next` and `eslint-config-prettier`)
- `tsconfig`: `tsconfig.json`s used throughout the monorepo
- `tailwind-config`: shared `tailwind.config.js` used throughout the monorepo

### Develop

To develop all apps and packages, run the following command:

```shell
npm run dev
```

### Add packages

To add packages to a specify workspace, run the following command:

```shell
npm install -D react --workspace=ui
```

### Build

To build all apps and packages, run the following command:

```shell
npm run build
```