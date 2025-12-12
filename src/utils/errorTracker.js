// Error Tracking System

const STORAGE_KEY = 'achieve_errors';
const MAX_ERRORS = 100;

class ErrorTrackerClass {
  constructor() {
    this.errors = this.loadErrors();
    this.setupGlobalHandlers();
  }

  loadErrors() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
    } catch {
      return [];
    }
  }

  saveErrors() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(this.errors));
  }

  log(error, type = 'error', context = {}) {
    const entry = {
      id: Date.now(),
      type, // 'error', 'warning', 'info'
      message: error.message || String(error),
      stack: error.stack || null,
      context: {
        url: window.location.href,
        userAgent: navigator.userAgent,
        timestamp: new Date().toISOString(),
        ...context
      }
    };

    this.errors.unshift(entry);
    
    // Keep only last MAX_ERRORS errors
    if (this.errors.length > MAX_ERRORS) {
      this.errors = this.errors.slice(0, MAX_ERRORS);
    }

    this.saveErrors();
    console.log(`[ErrorTracker] ${type}:`, error);

    return entry;
  }

  getErrors(filter = 'all') {
    if (filter === 'all') return this.errors;
    return this.errors.filter(e => e.type === filter);
  }

  getStats() {
    return {
      total: this.errors.length,
      errors: this.errors.filter(e => e.type === 'error').length,
      warnings: this.errors.filter(e => e.type === 'warning').length,
      info: this.errors.filter(e => e.type === 'info').length,
      lastError: this.errors[0] || null
    };
  }

  clear() {
    this.errors = [];
    localStorage.removeItem(STORAGE_KEY);
  }

  export() {
    return JSON.stringify(this.errors, null, 2);
  }

  setupGlobalHandlers() {
    // Global error handler
    window.onerror = (message, source, lineno, colno, error) => {
      this.log(error || { message, stack: `at ${source}:${lineno}:${colno}` }, 'error', {
        source, lineno, colno
      });
      return false;
    };

    // Unhandled promise rejection handler
    window.onunhandledrejection = (event) => {
      this.log(event.reason || { message: 'Unhandled Promise Rejection' }, 'error', {
        type: 'unhandledrejection'
      });
    };

    // Console error interceptor
    const originalConsoleError = console.error;
    console.error = (...args) => {
      const message = args.map(a => typeof a === 'object' ? JSON.stringify(a) : String(a)).join(' ');
      if (!message.includes('[ErrorTracker]')) {
        this.log({ message }, 'error', { source: 'console.error' });
      }
      originalConsoleError.apply(console, args);
    };

    // Console warn interceptor
    const originalConsoleWarn = console.warn;
    console.warn = (...args) => {
      const message = args.map(a => typeof a === 'object' ? JSON.stringify(a) : String(a)).join(' ');
      this.log({ message }, 'warning', { source: 'console.warn' });
      originalConsoleWarn.apply(console, args);
    };
  }
}

export const ErrorTracker = new ErrorTrackerClass();




