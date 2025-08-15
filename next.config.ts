import analyzer from '@next/bundle-analyzer';
import { withSentryConfig } from '@sentry/nextjs';
import withSerwistInit from '@serwist/next';
import type { NextConfig } from 'next';
import ReactComponentName from 'react-scan/react-component-name/webpack';
import path from 'node:path';

// --- 环境标记 ---
const isProd = process.env.NODE_ENV === 'production';
const isDesktop = process.env.NEXT_PUBLIC_IS_DESKTOP_APP === '1';
const enableReactScan = !!process.env.REACT_SCAN_MONITOR_API_KEY;
const isUsePglite = process.env.NEXT_PUBLIC_CLIENT_DB === 'pglite';
const basePath = process.env.NEXT_PUBLIC_BASE_PATH;

// 对于 monorepo/workspaces，Next 需要一个 “追踪根目录” 来正确打包 standalone 依赖。
// 支持在 CI 里通过环境变量覆盖，例如：OUTPUT_FILE_TRACING_ROOT=/codebuild/output/src123/src
const outputFileTracingRoot =
  process.env.OUTPUT_FILE_TRACING_ROOT
    ? path.resolve(process.env.OUTPUT_FILE_TRACING_ROOT)
    : undefined;

const nextConfig: NextConfig = {
  // 关键：产出 standalone
  output: 'standalone',

  // 追踪额外文件（你原有的规则保留）
  outputFileTracingIncludes: { '*': ['public/**/*', '.next/static/**/*'] },

  // 如果提供了 tracing 根（monorepo 更稳），就启用
  ...(outputFileTracingRoot ? { outputFileTracingRoot } : {}),

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
    // OIDC 依赖 constructor.name，避免 SWC 去名
    serverMinification: false,
    webVitalsAttribution: ['CLS', 'LCP'],
  },

  // Turbopack 配置
  turbopack: {
    rules: {
      '*.m?js': {
        loaders: ['@next/swc-loader'],
        as: 'javascript/auto',
      },
    },
  },

  async headers() {
    return [
      { headers: [{ key: 'x-robots-tag', value: 'all' }], source: '/:path*' },
      { headers: [{ key: 'Cache-Control', value: 'public, max-age=31536000, immutable' }], source: '/icons/(.*).(png|jpe?g|gif|svg|ico|webp)' },
      { headers: [
          { key: 'Cache-Control', value: 'public, max-age=31536000, immutable' },
          { key: 'CDN-Cache-Control', value: 'public, max-age=31536000, immutable' },
          { key: 'Vercel-CDN-Cache-Control', value: 'public, max-age=31536000, immutable' },
        ], source: '/images/(.*).(png|jpe?g|gif|svg|ico|webp)' },
      { headers: [
          { key: 'Cache-Control', value: 'public, max-age=31536000, immutable' },
          { key: 'CDN-Cache-Control', value: 'public, max-age=31536000, immutable' },
          { key: 'Vercel-CDN-Cache-Control', value: 'public, max-age=31536000, immutable' },
        ], source: '/videos/(.*).(mp4|webm|ogg|avi|mov|wmv|flv|mkv)' },
      { headers: [
          { key: 'Cache-Control', value: 'public, max-age=31536000, immutable' },
          { key: 'CDN-Cache-Control', value: 'public, max-age=31536000, immutable' },
          { key: 'Vercel-CDN-Cache-Control', value: 'public, max-age=31536000, immutable' },
        ], source: '/screenshots/(.*).(png|jpe?g|gif|svg|ico|webp)' },
      { headers: [
          { key: 'Cache-Control', value: 'public, max-age=31536000, immutable' },
          { key: 'CDN-Cache-Control', value: 'public, max-age=31536000, immutable' },
          { key: 'Vercel-CDN-Cache-Control', value: 'public, max-age=31536000, immutable' },
        ], source: '/og/(.*).(png|jpe?g|gif|svg|ico|webp)' },
      { headers: [
          { key: 'Cache-Control', value: 'public, max-age=31536000, immutable' },
          { key: 'CDN-Cache-Control', value: 'public, max-age=31536000, immutable' },
        ], source: '/favicon.ico' },
      { headers: [
          { key: 'Cache-Control', value: 'public, max-age=31536000, immutable' },
          { key: 'CDN-Cache-Control', value: 'public, max-age=31536000, immutable' },
        ], source: '/favicon-32x32.ico' },
      { headers: [
          { key: 'Cache-Control', value: 'public, max-age=31536000, immutable' },
          { key: 'CDN-Cache-Control', value: 'public, max-age=31536000, immutable' },
        ], source: '/apple-touch-icon.png' },
    ];
  },

  logging: {
    fetches: { fullUrl: true, hmrRefreshes: true },
  },

  poweredByHeader: false,

  reactStrictMode: true,

  redirects: async () => [
    { destination: '/sitemap-index.xml', permanent: true, source: '/sitemap.xml' },
    { destination: '/sitemap-index.xml', permanent: true, source: '/sitemap-0.xml' },
    { destination: '/sitemap/plugins-1.xml', permanent: true, source: '/sitemap/plugins.xml' },
    { destination: '/sitemap/assistants-1.xml', permanent: true, source: '/sitemap/assistants.xml' },
    { destination: '/manifest.webmanifest', permanent: true, source: '/manifest.json' },
    { destination: '/discover/assistant', permanent: true, source: '/discover/assistants' },
    { destination: '/discover/plugin', permanent: true, source: '/discover/plugins' },
    { destination: '/discover/model', permanent: true, source: '/discover/models' },
    { destination: '/discover/provider', permanent: true, source: '/discover/providers' },
    { destination: '/settings/common', permanent: true, source: '/settings' },
    { destination: '/chat', permanent: true, source: '/welcome' },
    { destination: '/files', permanent: false, source: '/repos' },
  ],

  // dev 用 turbopack 时避免 pglite 被外部化
  serverExternalPackages: isProd ? ['@electric-sql/pglite'] : undefined,

  transpilePackages: ['pdfjs-dist', 'mermaid'],

  webpack(config) {
    config.experiments = { asyncWebAssembly: true, layers: true };

    // 优化 webpack 缓存性能
    config.cache = {
      ...config.cache,
      compression: 'gzip',
      maxMemoryGenerations: 1,
    };

    if (enableReactScan && !isUsePglite) {
      config.plugins.push(ReactComponentName({}));
    }

    // shikiji 兼容
    config.module.rules.push({
      resolve: { fullySpecified: false },
      test: /\.m?js$/,
      type: 'javascript/auto',
    });

    // pino pretty 仅开发用
    config.externals.push('pino-pretty');

    // 禁用可选的原生 canvas 依赖，避免服务器缺二进制时报错
    config.resolve.alias.canvas = false;

    // 避免一些 Node 内置模块在浏览器端被打进包
    config.resolve.fallback = {
      ...config.resolve.fallback,
      crypto: 'crypto-browserify',
      fs: false,
      os: false,
      path: 'path-browserify',
      stream: 'stream-browserify',
      zipfile: false,
    };

    return config;
  },
};

const noWrapper = (config: NextConfig) => config;
const withBundleAnalyzer = process.env.ANALYZE === 'true' ? analyzer() : noWrapper;

const hasSentry = !!process.env.NEXT_PUBLIC_SENTRY_DSN;
const withSentry =
  isProd && hasSentry
    ? (c: NextConfig) =>
        withSentryConfig(
          c,
          {
            org: process.env.SENTRY_ORG,
            project: process.env.SENTRY_PROJECT,
            silent: true,
          },
          {
            automaticVercelMonitors: true,
            disableLogger: true,
            hideSourceMaps: true,
            transpileClientSDK: true,
            tunnelRoute: '/monitoring',
            widenClientFileUpload: true,
          },
        )
    : noWrapper;

const withPWA =
  isProd && !isDesktop
    ? withSerwistInit({ register: false, swDest: 'public/sw.js', swSrc: 'src/app/sw.ts' })
    : noWrapper;

export default withBundleAnalyzer(withPWA(withSentry(nextConfig) as NextConfig));
