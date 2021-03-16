const path = require('path');
const glob = require('glob');
const HardSourceWebpackPlugin = require('hard-source-webpack-plugin');
const TerserPlugin = require('terser-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = (env, options) => {
    const devMode = options.mode !== 'production';

    return {
        target: 'node',
        optimization: {
            minimizer: [
                new TerserPlugin({ cache: true, parallel: true, sourceMap: devMode })
            ]
        },
        entry: {
            'app': glob.sync('./vendor/**/*.js').concat(['./js/app.js'])
        },
        output: {
            filename: '[name].js',
            path: path.resolve(__dirname, './dist/js'),
            publicPath: '/js/'
        },
        devtool: devMode ? 'eval-cheap-module-source-map' : undefined,
        module: {
            rules: [
                {
                    test: /\.js$/,
                    exclude: /node_modules/,
                    use: {
                        loader: 'babel-loader'
                    }
                }
            ]
        },
        plugins: [].concat(devMode ? [new HardSourceWebpackPlugin()] : [])
    }
};
