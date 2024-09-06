const { devServerPort } = require("./config")
const webpack = require('webpack')
// Extracts CSS into .css file
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const RemoveEmptyScriptsPlugin = require('webpack-remove-empty-scripts');
const WebpackAssetsManifest = require('webpack-assets-manifest');

module.exports = (isProduction) => {
  const devServerManifestPublicPath = `http://localhost:${devServerPort}/packs/`;
  const plugins = [
    new WebpackAssetsManifest({
      output: "manifest.json",
      writeToDisk: true,
      publicPath: isProduction ? true : devServerManifestPublicPath,
      entrypoints: true,
      entrypointsUseAssets: true,
    }),
    new RemoveEmptyScriptsPlugin(),
    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
      'window.jQuery': 'jquery',
    })
  ]

  const hash = isProduction ? '-[contenthash:8]' : ''
  plugins.push(
    new MiniCssExtractPlugin({
      filename: `css/[name]${hash}.css`,
      chunkFilename: `css/[id]${hash}.css`
    })
  )

  return plugins;
}