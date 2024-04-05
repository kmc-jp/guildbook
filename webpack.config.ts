import fs from 'fs';
import glob from 'glob';
import path from 'path';

import webpack from 'webpack';
import WebpackDevServer from 'webpack-dev-server';

import CompressionPlugin from 'compression-webpack-plugin';
import MiniCssExtractPlugin from 'mini-css-extract-plugin';
import WebpackAssetsManifest from 'webpack-assets-manifest';

declare module 'webpack' {
  // https://github.com/DefinitelyTyped/DefinitelyTyped/issues/51091
  interface CliConfigOptions {
    mode?: webpack.Configuration['mode'];
  }
  type ConfigurationFactory = ((
    env: string | Record<string, boolean | number | string> | undefined,
    args: CliConfigOptions,
  ) => Configuration | Promise<Configuration>);
}


const genConfig: webpack.ConfigurationFactory = (_env, argv) => {
  const isProduction = argv.mode === 'production';

  const context = path.join(__dirname, 'javascript')
  const entry = glob.sync(path.join(context, 'packs/*')).reduce((entry, pack) => {
    const bundle = path.relative(context, pack);
    return {
      ...entry,
      [path.basename(bundle, path.extname(bundle))]: `./${bundle}`,
    };
  }, {});

  const publicPath = process.env.WEBPACK_DEV_SERVER_URL || '/assets/';

  const plugins: webpack.Configuration['plugins'] = [
    new WebpackAssetsManifest({
      integrity: false,
      entrypoints: true,
      writeToDisk: true,
    }),
    new MiniCssExtractPlugin({
      filename: '[name].css',
    }),
  ];
  if (isProduction) {
    plugins.push(
      new CompressionPlugin({
        test: /\.(js|css|html|json|ico|svg|eot|otf|ttf)$/,
      })
    );
  }

  const optimization: webpack.Configuration['optimization'] = {
    splitChunks: {
      chunks: 'all',
    },
  };

  return {
    context,
    entry,
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
    plugins,
    optimization,
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

export default genConfig;
