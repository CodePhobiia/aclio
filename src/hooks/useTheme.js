// Theme Management Hook
import { useState, useEffect, useCallback } from 'react';
import { saveTheme, loadTheme } from '../utils/storage';

export function useTheme() {
  const [theme, setThemeState] = useState(() => loadTheme());

  // Apply theme to document
  useEffect(() => {
    if (theme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
    saveTheme(theme);
  }, [theme]);

  // Toggle theme
  const toggleTheme = useCallback(() => {
    setThemeState(prev => prev === 'dark' ? 'light' : 'dark');
  }, []);

  // Set specific theme
  const setTheme = useCallback((newTheme) => {
    if (newTheme === 'dark' || newTheme === 'light') {
      setThemeState(newTheme);
    }
  }, []);

  return {
    theme,
    isDark: theme === 'dark',
    toggleTheme,
    setTheme
  };
}




