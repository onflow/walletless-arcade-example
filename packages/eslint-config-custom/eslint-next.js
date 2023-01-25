module.exports = {
      "root": true,
  extends: [
    'eslint:recommended',
    "plugin:react/recommended",
    'plugin:@typescript-eslint/recommended',
    'next',
    "next/core-web-vitals",
    'turbo',
    'prettier',
  ],
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint'],
  root: true,
  rules: {
    '@next/next/no-html-link-for-pages': 'off',
    "@typescript-eslint/consistent-type-imports": "warn",
    'react/jsx-key': 'off',
  },
}
