const path = require('path')

module.exports = {
  entry: './src/js/index.js',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'main.js'
  },
  module: {
    rules: [{
      test: /\.elm$/,
      exclude: [/elm-stuff/, /node_modules/],
      use: {
        loader: 'elm-webpack-loader',
        options: {}
      }
    }, {
      test: /\.(sass)$/,
      use: [{
        loader: 'style-loader' // inject CSS to page
      }, {
        loader: 'css-loader' // translates CSS into CommonJS modules
      }, {
        loader: 'postcss-loader', // Run post css actions
        options: {
          postcssOptions: {
            plugins: [
              require('precss'),
              require('autoprefixer')
            ]
          }

        }
      }, {
        loader: 'sass-loader' // compiles Sass to CSS
      }]
    }]
  }
}
