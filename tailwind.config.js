/** @type {import('tailwindcss').Config} */
const defaultTheme = require('tailwindcss/defaultTheme');

module.exports = {
  content: [
    "config.rb",
    "source/**/*.erb"
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Urbanist', ...defaultTheme.fontFamily.sans],
        default: [...defaultTheme.fontFamily.sans],
      }
    },
  },
  plugins: [
    require('@tailwindcss/typography')
  ],
}

