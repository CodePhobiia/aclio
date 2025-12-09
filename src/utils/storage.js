// Local Storage Utilities

// Goals
export const saveGoals = (goals) => {
  localStorage.setItem('achieve_goals', JSON.stringify(goals));
};

export const loadGoals = () => {
  try {
    return JSON.parse(localStorage.getItem('achieve_goals') || '[]');
  } catch {
    return [];
  }
};

// Onboarding
export const hasOnboarded = () => {
  return localStorage.getItem('achieve_onboarded') === 'true';
};

export const setOnboarded = () => {
  localStorage.setItem('achieve_onboarded', 'true');
};

export const clearOnboarded = () => {
  localStorage.removeItem('achieve_onboarded');
};

// User Profile
export const saveUserProfile = (profile) => {
  localStorage.setItem('achieve_profile', JSON.stringify(profile));
};

export const loadUserProfile = () => {
  try {
    return JSON.parse(localStorage.getItem('achieve_profile') || 'null');
  } catch {
    return null;
  }
};

// Theme
export const saveTheme = (theme) => {
  localStorage.setItem('achieve_theme', theme);
};

export const loadTheme = () => {
  return localStorage.getItem('achieve_theme') || 'light';
};

// Points & Gamification
export const savePoints = (points) => {
  localStorage.setItem('achieve_points', String(points));
};

export const loadPoints = () => {
  return parseInt(localStorage.getItem('achieve_points') || '0');
};

export const saveStreak = (streakData) => {
  localStorage.setItem('achieve_streak', JSON.stringify(streakData));
};

export const loadStreak = () => {
  try {
    return JSON.parse(localStorage.getItem('achieve_streak') || '{"current":0,"best":0,"lastActive":null}');
  } catch {
    return { current: 0, best: 0, lastActive: null };
  }
};

// Premium
export const savePremium = (isPremium) => {
  localStorage.setItem('achieve_premium', String(isPremium));
};

export const loadPremium = () => {
  return localStorage.getItem('achieve_premium') === 'true';
};

// Achievements
export const saveAchievements = (achievements) => {
  localStorage.setItem('achieve_badges', JSON.stringify(achievements));
};

export const loadAchievements = () => {
  try {
    return JSON.parse(localStorage.getItem('achieve_badges') || '[]');
  } catch {
    return [];
  }
};

// Notifications
export const saveNotificationsEnabled = (enabled) => {
  localStorage.setItem('achieve_notifications', String(enabled));
};

export const loadNotificationsEnabled = () => {
  return localStorage.getItem('achieve_notifications') === 'true';
};

// Location
export const saveLocation = (location) => {
  localStorage.setItem('achieve_location', JSON.stringify(location));
};

export const loadLocation = () => {
  try {
    return JSON.parse(localStorage.getItem('achieve_location') || 'null');
  } catch {
    return null;
  }
};

// Daily Limits (for free users)
export const getDailyUses = (key) => {
  try {
    const saved = localStorage.getItem(key);
    if (saved) {
      const { date, count } = JSON.parse(saved);
      if (date === new Date().toDateString()) return count;
    }
    return 0;
  } catch {
    return 0;
  }
};

export const incrementDailyUses = (key) => {
  const current = getDailyUses(key);
  localStorage.setItem(key, JSON.stringify({
    date: new Date().toDateString(),
    count: current + 1
  }));
  return current + 1;
};

// Do It For Me saved responses
export const saveDoItForMe = (data) => {
  localStorage.setItem('achieve_doitforme', JSON.stringify(data));
};

export const loadDoItForMe = () => {
  try {
    return JSON.parse(localStorage.getItem('achieve_doitforme') || '{}');
  } catch {
    return {};
  }
};

// Daily bonus
export const hasDailyBonusClaimed = () => {
  return localStorage.getItem('achieve_daily_bonus') === new Date().toDateString();
};

export const claimDailyBonus = () => {
  localStorage.setItem('achieve_daily_bonus', new Date().toDateString());
};

// Clear all data (for logout)
export const clearAllData = () => {
  const keys = [
    'achieve_goals',
    'achieve_onboarded',
    'achieve_profile',
    'achieve_theme',
    'achieve_points',
    'achieve_streak',
    'achieve_premium',
    'achieve_badges',
    'achieve_notifications',
    'achieve_location',
    'achieve_doitforme',
    'achieve_daily_bonus',
    'achieve_doitforme_uses',
    'achieve_expand_uses',
    'achieve_errors'
  ];
  keys.forEach(key => localStorage.removeItem(key));
};

