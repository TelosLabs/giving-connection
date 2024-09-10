// Extracts CSS into .css file
const MiniCssExtractPlugin = require('mini-css-extract-plugin');


module.exports = () => [
  // Raw
  {
    test: [ /\.html$/ ],
    exclude: [ /\.(js|mjs|jsx|ts|tsx)$/ ],
    type: 'asset/source'
  },
  // File
  {
    test: [
      /\.bmp$/,   /\.gif$/,
      /\.jpe?g$/, /\.png$/,
      /\.tiff$/,  /\.ico$/,
      /\.avif$/,  /\.webp$/,
      /\.eot$/,   /\.otf$/,
      /\.ttf$/,   /\.woff$/,
      /\.woff2$/, /\.svg$/
    ],
    exclude: [ /\.(js|mjs|jsx|ts|tsx)$/ ],
    type: 'asset/resource',
    generator: { filename: 'static/[hash][ext][query]' }
  },
  // CSS
  {
    test: /\.(css)$/i,
    use: [
      MiniCssExtractPlugin.loader,
      'style-loader',
      'css-loader',
      'postcss-loader'
    ]
  },
  // SASS
  {
    test: /\.(scss|sass)(\.erb)?$/i,
    use: [
      MiniCssExtractPlugin.loader,
      'style-loader',
      'css-loader',
      'sass-loader'
    ]
  },
]
