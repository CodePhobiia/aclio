// Gamification System Configuration

export const LEVELS = [
  { level: 1, name: 'Beginner', minPoints: 0, icon: 'star' },
  { level: 2, name: 'Explorer', minPoints: 100, icon: 'zap' },
  { level: 3, name: 'Achiever', minPoints: 300, icon: 'flame' },
  { level: 4, name: 'Champion', minPoints: 600, icon: 'trophy' },
  { level: 5, name: 'Master', minPoints: 1000, icon: 'award' },
  { level: 6, name: 'Expert', minPoints: 1500, icon: 'crown' },
  { level: 7, name: 'Legend', minPoints: 2500, icon: 'gem' },
  { level: 8, name: 'Elite', minPoints: 4000, icon: 'sparkles' },
  { level: 9, name: 'Grandmaster', minPoints: 6000, icon: 'rocket' },
  { level: 10, name: 'Ultimate', minPoints: 10000, icon: 'target' },
];

export const POINTS = {
  STEP_COMPLETE: 10,
  GOAL_COMPLETE: 50,
  DAILY_BONUS: 25,
  STREAK_BONUS: 5, // per day of streak
  FIRST_GOAL: 30,
};

export const ACHIEVEMENTS = [
  { 
    id: 'first_goal', 
    name: 'Goal Setter', 
    desc: 'Created your first goal', 
    icon: 'star', 
    gradient: 'linear-gradient(135deg, #8b5cf6, #6d28d9)', 
    check: (goals) => goals.length >= 1 
  },
  { 
    id: 'first_step', 
    name: 'First Step', 
    desc: 'Completed your first step', 
    icon: 'rocket', 
    gradient: 'linear-gradient(135deg, #10b981, #059669)', 
    check: (goals) => goals.some(g => g.completedSteps?.length > 0) 
  },
  { 
    id: 'first_complete', 
    name: 'Achiever', 
    desc: 'Completed your first goal', 
    icon: 'trophy', 
    gradient: 'linear-gradient(135deg, #f59e0b, #d97706)', 
    check: (goals, getProgress) => goals.some(g => getProgress(g) === 100) 
  },
  { 
    id: 'streak_3', 
    name: 'On Fire', 
    desc: '3 day streak', 
    icon: 'flame', 
    gradient: 'linear-gradient(135deg, #ef4444, #dc2626)', 
    check: (goals, getProgress, streak) => streak >= 3 
  },
  { 
    id: 'streak_7', 
    name: 'Unstoppable', 
    desc: '7 day streak', 
    icon: 'zap', 
    gradient: 'linear-gradient(135deg, #3b82f6, #1d4ed8)', 
    check: (goals, getProgress, streak) => streak >= 7 
  },
  { 
    id: 'five_goals', 
    name: 'Ambitious', 
    desc: 'Created 5 goals', 
    icon: 'target', 
    gradient: 'linear-gradient(135deg, #ec4899, #db2777)', 
    check: (goals) => goals.length >= 5 
  },
  { 
    id: 'three_complete', 
    name: 'Hat Trick', 
    desc: 'Completed 3 goals', 
    icon: 'award', 
    gradient: 'linear-gradient(135deg, #14b8a6, #0d9488)', 
    check: (goals, getProgress) => goals.filter(g => getProgress(g) === 100).length >= 3 
  },
  { 
    id: 'ten_steps', 
    name: 'Step Master', 
    desc: 'Completed 10 steps', 
    icon: 'activity', 
    gradient: 'linear-gradient(135deg, #6366f1, #4f46e5)', 
    check: (goals) => goals.reduce((sum, g) => sum + (g.completedSteps?.length || 0), 0) >= 10 
  },
  { 
    id: 'fifty_steps', 
    name: 'Dedicated', 
    desc: 'Completed 50 steps', 
    icon: 'gem', 
    gradient: 'linear-gradient(135deg, #0ea5e9, #0284c7)', 
    check: (goals) => goals.reduce((sum, g) => sum + (g.completedSteps?.length || 0), 0) >= 50 
  },
  { 
    id: 'hundred_points', 
    name: 'Century', 
    desc: 'Earned 100 points', 
    icon: 'coins', 
    gradient: 'linear-gradient(135deg, #a855f7, #9333ea)', 
    check: (goals, getProgress, streak, points) => points >= 100 
  },
  { 
    id: 'five_hundred_points', 
    name: 'Elite', 
    desc: 'Earned 500 points', 
    icon: 'crown', 
    gradient: 'linear-gradient(135deg, #facc15, #eab308)', 
    check: (goals, getProgress, streak, points) => points >= 500 
  },
  { 
    id: 'level_5', 
    name: 'Master', 
    desc: 'Reached Level 5', 
    icon: 'sparkles', 
    gradient: 'linear-gradient(135deg, #f97316, #ea580c)', 
    check: (goals, getProgress, streak, points, getLevel) => getLevel(points).level >= 5 
  },
];

// Helper functions for gamification
export const getLevel = (points) => {
  for (let i = LEVELS.length - 1; i >= 0; i--) {
    if (points >= LEVELS[i].minPoints) return LEVELS[i];
  }
  return LEVELS[0];
};

export const getNextLevel = (points) => {
  const currentLevel = getLevel(points);
  const nextIdx = LEVELS.findIndex(l => l.level === currentLevel.level) + 1;
  return nextIdx < LEVELS.length ? LEVELS[nextIdx] : null;
};

export const getLevelProgress = (points) => {
  const current = getLevel(points);
  const next = getNextLevel(points);
  if (!next) return 100;
  const progressInLevel = points - current.minPoints;
  const levelRange = next.minPoints - current.minPoints;
  return Math.round((progressInLevel / levelRange) * 100);
};







