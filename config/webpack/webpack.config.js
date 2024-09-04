const path = require('path');
const webpack = require('webpack');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const RemoveEmptyScriptsPlugin = require('webpack-remove-empty-scripts');

module.exports = (env, argv) => {
  const isProduction = argv.mode === 'production';

  return {
    mode: isProduction ? 'production' : 'development',  
    entry: {
      application: [
        './app/javascript/packs/application.js',
        './app/javascript/stylesheets/application.scss'
      ] 
    },
    output: {
      path: path.resolve(__dirname, 'public/packs'),
      filename: '[name].js',
      publicPath: '/packs/'
    },
    resolve: {
      extensions: ['.mjs', '.js', '.sass', '.scss', '.css', '.module.sass', '.module.scss', '.module.css', '.png', '.svg', '.gif', '.jpeg', '.jpg'],
      modules: [path.resolve(__dirname, 'app/components'), 'node_modules']
    },
    module: {
      rules: [
        {
          test: /\.(js|mjs)$/,
          exclude: /node_modules/,
          use: {
            loader: 'babel-loader'
          }
        },
        {
          test: /\.(css|scss|sass)$/,
          use: [MiniCssExtractPlugin.loader, 'css-loader', 'sass-loader'],
        },
        {
          test: /\.(png|jpe?g|gif|eot|woff2|woff|ttf|svg)$/i,
          use:'file-loader'
        }
      ]
    },
    plugins: [
      new webpack.optimize.LimitChunkCountPlugin({
        maxChunks: 1
      }),
      new webpack.ProvidePlugin({
        $: 'jquery/src/jquery',
        jQuery: 'jquery/src/jquery'
      }),
      new MiniCssExtractPlugin(),
      new RemoveEmptyScriptsPlugin()
    ],
    devServer: {
      host: 'localhost',
      port: 3035,
      publicPath: '/packs/',
      hot: false,
      inline: true,
      overlay: true,
      compress: true,
      disableHostCheck: true,
      headers: {
        'Access-Control-Allow-Origin': '*'
      },
      watchOptions: {
        ignored: '**/node_modules/**'
      }
    }
  };
};
