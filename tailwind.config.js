module.exports = {
  purge: [],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {
      colors: {
        blue: {
          dark: '#113c7b',
          medium: '#0782d0',
          light: '#9abee3',
          pale: '#e2ecf7'
        },
        seafoam: {
          DEFAULT: '#9ae2e0'
        },
        salmon: {
          DEFAULT: '#fc8383'
        },
        gray: {
          'gray-1': '#f9fafc',
          'gray-2': '#eff2f7',
          'gray-3': '#e5e9f2',
          'gray-4': '#D3dce6',
          'gray-5': '#c2cedB',
          'gray-6': '#8492a6',
          'gray-7': '#3c4858'
        },
        states: {
          success: '#37ccb2',
          error: '#ea343e',
          warning: '#febb5a',
          disabled: '#eff2f7'
        },
        copy: {
          white: '#ffffff'
        }
      },
      zIndex: {
        '-1' : '-1',
      },
      screens: {
        'xs': '375px',
      }
    },
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
