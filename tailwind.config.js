const { screens } = require('tailwindcss/defaultTheme')

module.exports = {
  purge: [],
  darkMode: false, // or 'media' or 'class'
  theme: {
    screens: {
      'xs': '375px',
      'mid': '870px',
      ...screens,
    },
    extend: {
      colors: {
        gray: {
          'gray-1': '#050504',
          'gray-3': '#3c4858',
          'gray-4': '#8492a6',
          'gray-5': '#c2cedB',
          'gray-6': '#D3dce6',
          'gray-7': '#e5e9f2',
          'gray-8': '#eff2f7',
          'gray-9': '#f9fafc'
        },
        red: {
          DEFAULT: '#F48284',
        }
      },
    },
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
