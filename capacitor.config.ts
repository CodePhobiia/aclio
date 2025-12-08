import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.ahmed.aclio',
  appName: 'Aclio',
  webDir: 'dist',
  server: {
    // For development, you can use your local server
    // url: 'http://localhost:8080',
    // cleartext: true,
  },
  ios: {
    contentInset: 'automatic',
    preferredContentMode: 'mobile',
    scheme: 'Aclio',
  },
  plugins: {
    // RevenueCat plugin config (if using Capacitor plugin)
  },
};

export default config;

