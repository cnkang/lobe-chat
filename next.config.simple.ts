import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  output: 'standalone',
  reactStrictMode: true,
  experimental: {
    serverMinification: false,
  },
  webpack(config) {
    config.externals.push('pino-pretty');
    return config;
  },
};

export default nextConfig;