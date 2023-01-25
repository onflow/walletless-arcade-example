/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    'src/**/*.{js,ts,jsx,tsx}',
    // include packages if not transpiling
    '../../packages/ui/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
