import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './styles/index.css';

// Initialize error tracking
import { ErrorTracker } from './utils/errorTracker';
import { StatusBar, Style } from '@capacitor/status-bar';

// Configure status bar for full-bleed layout
StatusBar.setOverlaysWebView({ overlay: true }).catch(() => {});
StatusBar.setStyle({ style: Style.Dark }).catch(() => {});
StatusBar.setBackgroundColor({ color: '#020617' }).catch(() => {});

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
