module.exports = {
  purge: [],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {
      colors: {
        blue:{
          'gradient-1': '#2C3E6B',
          'gradient-2': '#0068AF',
          'dark': '#113C7B',
          'medium': '#0782D0',
        },
        'seafoam': '#9AE2E0',
        grey:{
          4: '#8492A6',
          5: '#C2CEDB',
          6: '#D3DCE6',
          7: '#E5E9F2',
          8: '#EFF2F7',
          9: '#F9FAFC',
        },
        salmon: '#FC8383',
      },
      textColor: {
        grey: {
          2: '#1F2D3D',
          3: '#3C4858',
        },
        blue: {
          medium: '#0782D0',
        },
        green: {
          fountain: '#3DC5B5',
        },
      },
      maxWidth: {
        '327px': '327px',
        '375px': '375px',
        '402px': '402px',
        '470px': '470px',
        '656px': '656px',
      },
      minHeight: {
        '46px': '46px',
      },
      maxHeight: {
        '500px': '500px',
      },
      height: {
        'min-content': 'min-content',
        '46px': '46px',
        '400px': '400px',
      },
      borderRadius: {
        '6px': '6px',
      },
      boxShadow: {
        'input': '0px 4px 4px rgba(0, 0, 0, 0.01)',
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
