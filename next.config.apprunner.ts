import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  output: 'standalone',
  reactStrictMode: true,
  compress: true,
  eslint: {
    ignoreDuringBuilds: true,
  },
  typescript: {
    ignoreBuildErrors: true,
  },
  experimental: {
    serverMinification: false,
  },
  webpack(config, { isServer }) {
    // Externalize problematic packages
    config.externals.push('pino-pretty');
    
    // Fix resolve issues
    config.resolve.alias.canvas = false;
    
    config.resolve.fallback = {
      ...config.resolve.fallback,
      zipfile: false,
    };
    
    // Handle client-side only modules
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
      };
    }
    
    return config;
  },
  // Disable some features that might cause issues
  serverExternalPackages: ['@electric-sql/pglite', 'epub2'],
  transpilePackages: ['pdfjs-dist'],
};

export default nextConfig;