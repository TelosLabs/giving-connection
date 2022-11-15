const { environment } = require('@rails/webpacker')

const webpack = require('webpack')

environment.plugins.prepend('Provide',
  new webpack.ProvidePlugin({
    $: 'jquery/src/jquery',
    jQuery: 'jquery/src/jquery'
  })
)

environment.plugins.append(
  'NormalReplace',
  new webpack.NormalModuleReplacementPlugin(/swiper\/bundle/, 'swiper/swiper-bundle')
);


module.exports = environment
