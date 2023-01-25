module.exports = {
  env: {
    browser: true,
    es2021: true,
  },
  extends: [
    'plugin:@typescript-eslint/recommended',
    'next',
    'next/core-web-vitals',
    'turbo',
    'prettier',
  ],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaFeatures: {
      jsx: true,
    },
    ecmaVersion: 12,
    sourceType: 'module',
  },
  plugins: ['@typescript-eslint'],
  rules: {
    '@next/next/no-html-link-for-pages': 'off',
    '@typescript-eslint/consistent-type-imports': 'warn',
    'react/jsx-key': 'off',
  },
}
