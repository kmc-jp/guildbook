const fs = require('fs');
const glob = require('glob');
const path = require('path');
const yaml = require('js-yaml');

const CompressionPlugin = require('compression-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const WebpackAssetsManifest = require('webpack-assets-manifest');

const loadSettings = (mode) => {
    const data = yaml.load(fs.readFileSync(path.join(__dirname, 'config/guildbook.yml')));
    return (data.production || data.development) ? data[mode] : data;
}

module.exports = (env, argv) => {
    const isProduction = argv.mode === 'production';
    const settings = loadSettings(argv.mode);

    const context = path.join(__dirname, 'javascript')
    const entry = glob.sync(path.join(context, 'packs/*')).reduce((entry, pack) => {
        const bundle = path.relative(context, pack);
        return Object.assign({}, entry, {
            [path.basename(bundle, path.extname(bundle))]: `./${bundle}`,
        });
    }, {});

    const publicPath = process.env.WEBPACK_DEV_SERVER_URL || settings.assets_uri || '/assets/';

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
            })
        );
    }

    const optimization = {
        splitChunks: {
            chunks: 'all',
        },
    };

    return {
        context: context,
        entry: entry,
        output: {
            path: path.join(__dirname, 'public/assets'),
            publicPath: publicPath,
        },
        module: {
            rules: [
                {
                    test: /\.(svg|eot|ttf|woff2?)$/,
                    type: 'asset/resource',
                },
                {
                    test: /\.tsx?$/,
                    use: [
                        {
                            loader: 'ts-loader',
                        },
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
                                postcssOptions: {
                                    plugins: [
                                        require('cssnano')({
                                            preset: require('cssnano-preset-default')({
                                                autoprefixer: false,
                                            }),
                                        }),
                                    ],
                                },
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
        resolve: {
            extensions: ['.ts', '.tsx', '.js'],
        },
        plugins: plugins,
        optimization: optimization,
        devtool: 'source-map',
        devServer: {
            static: {
                directory: path.join(__dirname, 'public'),
                publicPath: publicPath,
            },
            headers: {
                "Access-Control-Allow-Origin": "*",
            },
        },
    };
};
