/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: false, // Disabling SWC due to binary issues
  transpilePackages: ['@tanstack/react-query', '@tanstack/query-core'],
};

export default nextConfig;
