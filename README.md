# Flow Game Arcade and Prize Marketplace Demo

This is example Flow App was created to demonstrate walletless onboarding and promote composable, secure, and smooth UX for on-chain games without the need for a traditional backend.

### Apps and Packages

- `rps-game`: a [Next.js](https://nextjs.org/) app for the Rock Paper Scissors game
- `prize-market`: a [Next.js](https://nextjs.org/) app for the Prize Marketplace
- `ui`: a stub React component library shared by both `rps-game` and `prize-market` applications
- `eslint-config-custom`: `eslint` configurations (includes `eslint-config-next` and `eslint-config-prettier`)
- `tsconfig`: `tsconfig.json`s used throughout the monorepo

Each package/app is 100% [TypeScript](https://www.typescriptlang.org/).

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

### Develop

To develop all apps and packages, run the following command:

```shell
npm run dev
```

## Useful Links for Turborepo

Learn more about the power of Turborepo:

- [Tasks](https://turbo.build/repo/docs/core-concepts/monorepos/running-tasks)
- [Caching](https://turbo.build/repo/docs/core-concepts/caching)
- [Remote Caching](https://turbo.build/repo/docs/core-concepts/remote-caching)
- [Filtering](https://turbo.build/repo/docs/core-concepts/monorepos/filtering)
- [Configuration Options](https://turbo.build/repo/docs/reference/configuration)
- [CLI Usage](https://turbo.build/repo/docs/reference/command-line-reference)
