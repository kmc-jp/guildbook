const glob = require('glob');
const path = require('path');

const CompressionPlugin = require('compression-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const WebpackAssetsManifest = require('webpack-assets-manifest');

module.exports = (env, argv) => {
    const isProduction = argv.mode === 'production';

    const context = path.join(__dirname, 'javascript')
    const entry = glob.sync(path.join(context, 'packs/*')).reduce((entry, pack) => {
        const bundle = path.relative(context, pack);
        return Object.assign({}, entry, {
            [path.basename(bundle, path.extname(bundle))]: `./${bundle}`,
        });
    }, {});

    const plugins = [
        new WebpackAssetsManifest({
            integrity: false,
            entrypoints: true,
            writeToDisk: true,
        }),
        new MiniCssExtractPlugin({
            filename: '[name].css',
        }),
    ];
    if(isProduction) {
        plugins.push(
            new CompressionPlugin({
                test: /\.(js|css|html|json|ico|svg|eot|otf|ttf)$/,
                cache: true,
            })
        );
    }

    const optimization = {
        splitChunks: {
            chunks: 'all',
            name: !isProduction,
        },
    };

    return {
        context: context,
        entry: entry,
        output: {
            path: path.join(__dirname, 'public/assets'),
        },
        module: {
            rules: [
                {
                    test: /\.(svg|eot|ttf|woff2?)$/,
                    use: [
                        {
                            loader: 'file-loader',
                        }
                    ],
                },
                {
                    test: /\.scss$/,
                    use: [
                        MiniCssExtractPlugin.loader,
                        {
                            loader: 'css-loader',
                            options: {
                                sourceMap: true,
                            },
                        },
                        {
                            loader: 'postcss-loader',
                            options: {
                                sourceMap: true,
                                plugins: [
                                    require('cssnano')({
                                        autoprefixer: false,
                                    }),
                                ],
                            },
                        },
                        {
                            loader: 'resolve-url-loader',
                            options: {
                                sourceMap: true,
                            },
                        },
                        {
                            loader: 'sass-loader',
                            options: {
                                sourceMap: true,
                            },
                        },
                    ],
                },
            ],
        },
        plugins: plugins,
        optimization: optimization,
        devtool: 'source-map',
        devServer: {
            contentBase: path.join(__dirname, 'public'),
            publicPath: '/assets/',
            headers: {
                "Access-Control-Allow-Origin": "*",
            },
        },
    };
};
