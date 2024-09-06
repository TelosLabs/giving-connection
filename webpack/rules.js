const { resolve } = require("path");
const { sourcePath, additionalPaths } = require("./config")
// Extracts CSS into .css file
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

const getCssLoader = () => {
  return {
    loader: require.resolve('css-loader'),
    options: { sourceMap: true, importLoaders: 2 }
  }
}

const getSassLoader = () => {
  return {
    loader: require.resolve('sass-loader'),
    options: {
      sassOptions: {
        includePaths: additionalPaths
      }
    }
  }
}


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
      getCssLoader(),
    ]
  },
  // SASS
  {
    test: /\.(scss|sass)(\.erb)?$/i,
    use: [
      MiniCssExtractPlugin.loader,
      getCssLoader(),
      getSassLoader()
    ]
  },
]
