const { screens } = require('tailwindcss/defaultTheme')

module.exports = {
  purge: [],
  darkMode: false, // or 'media' or 'class'
  theme: {
    screens: {
      'xs': '375px',
      '525px' : '525px',
      'mid': '870px',
      ...screens,
    },
    extend: {
      fontSize: {
        '22px': '22px',
        '28px': '28px',
        '34px': '34px',
      },
      colors: {
        seafoam: {
          DEFAULT: '#9ae2e0'
        },
        salmon: {
          DEFAULT: '#fc8383'
        },
        red: {
          DEFAULT: '#f48284'
        },
        blue: {
          'gradient-1': '#2C3E6B',
          'gradient-2': '#0068AF',
          dark: '#113C7B',
          medium: '#0782D0',
          light: '#9abee3',
          pale: '#e2ecf7'
        },
        gray: {
          1: '#050504',
          2: '#1F2D3D',
          3: '#3C4858',
          4: '#8492A6',
          5: '#C2CEDB',
          6: '#D3DCE6',
          7: '#E5E9F2',
          8: '#EFF2F7',
          9: '#F9FAFC',
        },
        green: {
          fountain: '#3DC5B5',
        },
        states: {
          success: '#37ccb2',
          error: '#ea343e',
          warning: '#febb5a',
          disabled: '#eff2f7'
        },
        'electric-teal': '#d8fffe',
      },
      textColor: {
        gray: {
          2: '#1F2D3D',
          3: '#3C4858',
        },
        blue: {
          medium: '#0782D0',
        },
      },
      maxWidth: {
        '30%': "30%",
        '45%': "45%",
        '327px': '327px',
        '356px': '356px',
        '375px': '375px',
        '402px': '402px',
        '470px': '470px',
        '565px': '565px',
        '656px': '656px',
        ms: '343px'
      },
      minHeight: {
        '46px': '46px',
        '800px': '800px',
        '1150px': '1150px'

      },
      maxHeight: {
        '500px': '500px',
        '756px': '756px',
        '600px': '600px',
      },
      height: {
        'min-content': 'min-content',
        '46px': '46px',
        '300px': '300px',
        '350px': '350px',
        '400px': '400px',
        '85vh': '85vh',
      },
      borderRadius: {
        '6px': '6px',
      },
      boxShadow: {
        'input': '0px 4px 4px rgba(0, 0, 0, 0.01)',
      },
      zIndex: {
        '-1' : '-1',
      },
    },
  },
  variants: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
}
