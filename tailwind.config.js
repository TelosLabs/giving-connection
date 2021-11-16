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
          'gray-3': '#3c4858',
          'gray-4': '#8492a6',
          'gray-5': '#c2cedB',
          'gray-6': '#D3dce6',
          'gray-7': '#e5e9f2',
          'gray-8': '#eff2f7',
          'gray-9': '#f9fafc'
        },
        states: {
          success: '#37ccb2',
          error: '#f95b6e',
          warning: '#febb5a',
          disabled: '#eff2f7'
        },
        copy: {
          white: '#ffffff',
          'gray-2': '#1f2d3d'
        }
      },
      zIndex: {
        '-1' : '-1',
      },
      screens: {
        'xs': '375px',
      },
    },
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
