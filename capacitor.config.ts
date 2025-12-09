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
    backgroundColor: '#020617',
  },
  plugins: {
    StatusBar: {
      overlaysWebView: true,
      style: 'DARK',
      backgroundColor: '#020617',
    },
  },
};

export default config;

