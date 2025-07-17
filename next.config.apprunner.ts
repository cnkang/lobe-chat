import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  output: 'standalone',
  reactStrictMode: true,
  compress: true,
  experimental: {
    // Disable server minification to avoid issues with oidc provider
    serverMinification: false,
    // Optimize package imports for better build performance
    optimizePackageImports: [
      '@lobehub/ui',
      'lucide-react',
      'antd',
    ],
  },
  // Minimal webpack configuration for App Runner
  webpack(config) {
    // Externalize problematic packages
    config.externals.push('pino-pretty', 'canvas');
    
    // Disable canvas to avoid native dependencies
    config.resolve.alias.canvas = false;
    
    // Optimize for memory usage
    config.optimization = {
      ...config.optimization,
      splitChunks: {
        chunks: 'all',
        cacheGroups: {
          vendor: {
            test: /[\\/]node_modules[\\/]/,
            name: 'vendors',
            chunks: 'all',
          },
        },
      },
    };
    
    return config;
  },
  // Minimal headers for production
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'x-robots-tag',
            value: 'all',
          },
        ],
      },
    ];
  },
  // Simple redirects
  redirects: async () => [
    {
      source: '/settings',
      destination: '/settings/common',
      permanent: true,
    },
    {
      source: '/welcome',
      destination: '/chat',
      permanent: true,
    },
  ],
  // Disable some features that might cause issues
  serverExternalPackages: ['@electric-sql/pglite'],
  transpilePackages: ['pdfjs-dist'],
};

export default nextConfig;