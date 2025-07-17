import analyzer from '@next/bundle-analyzer';
import type { NextConfig } from 'next';
import ReactComponentName from 'react-scan/react-component-name/webpack';

const isProd = process.env.NODE_ENV === 'production';
const buildWithDocker = process.env.DOCKER === 'true';
const isDesktop = process.env.NEXT_PUBLIC_IS_DESKTOP_APP === '1';
const enableReactScan = !!process.env.REACT_SCAN_MONITOR_API_KEY;
const isUsePglite = process.env.NEXT_PUBLIC_CLIENT_DB === 'pglite';

const basePath = process.env.NEXT_PUBLIC_BASE_PATH;
const isStandaloneMode = buildWithDocker || isDesktop;

const standaloneConfig: NextConfig = {
  output: 'standalone',
  outputFileTracingIncludes: { '*': ['public/**/*', '.next/static/**/*'] },
};

const nextConfig: NextConfig = {
  ...(isStandaloneMode ? standaloneConfig : {}),
  basePath,
  compress: isProd,
  experimental: {
    optimizePackageImports: [
      'emoji-mart',
      '@emoji-mart/react',
      '@emoji-mart/data',
      '@icons-pack/react-simple-icons',
      '@lobehub/ui',
      'gpt-tokenizer',
    ],
    serverMinification: false,
    webVitalsAttribution: ['CLS', 'LCP'],
  },
  async headers() {
    return [
      {
        headers: [
          {
            key: 'x-robots-tag',
            value: 'all',
          },
        ],
        source: '/:path*',
      },
    ];
  },
  logging: {
    fetches: {
      fullUrl: true,
      hmrRefreshes: true,
    },
  },
  reactStrictMode: true,
  serverExternalPackages: isProd ? ['@electric-sql/pglite'] : undefined,
  transpilePackages: ['pdfjs-dist', 'mermaid'],
  webpack(config) {
    config.experiments = {
      asyncWebAssembly: true,
      layers: true,
    };

    if (enableReactScan && !isUsePglite) {
      config.plugins.push(ReactComponentName({}));
    }

    config.module.rules.push({
      resolve: {
        fullySpecified: false,
      },
      test: /\.m?js$/,
      type: 'javascript/auto',
    });

    config.externals.push('pino-pretty');
    config.resolve.alias.canvas = false;
    config.resolve.fallback = {
      ...config.resolve.fallback,
      zipfile: false,
    };
    return config;
  },
};

const noWrapper = (config: NextConfig) => config;
const withBundleAnalyzer = process.env.ANALYZE === 'true' ? analyzer() : noWrapper;

// 禁用 PWA 和 Sentry 来简化构建
export default withBundleAnalyzer(nextConfig);
