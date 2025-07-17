import type { NextConfig } from 'next';

const isProd = process.env.NODE_ENV === 'production';
const buildWithDocker = process.env.DOCKER === 'true';

const nextConfig: NextConfig = {
  output: 'standalone',
  compress: isProd,
  reactStrictMode: true,
  
  experimental: {
    serverMinification: false,
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
  
  webpack(config) {
    // 基本的webpack配置
    config.externals.push('pino-pretty');
    config.resolve.alias.canvas = false;
    config.resolve.fallback = {
      ...config.resolve.fallback,
      zipfile: false,
    };
    
    return config;
  },
};

export default nextConfig;