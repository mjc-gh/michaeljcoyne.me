/** @type {import('tailwindcss').Config} */
const defaultTheme = require('tailwindcss/defaultTheme');

module.exports = {
  content: [
    "_includes/**/*.html",
    "_includes/**/*.svg",
    "_layouts/**/*.html",
    "index.md",
    "projects.md",
    "_posts/**/*.md"
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
