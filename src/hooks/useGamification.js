// Gamification System Hook
import { useState, useCallback, useEffect } from 'react';
import { 
  loadPoints, savePoints,
  loadStreak, saveStreak,
  loadAchievements, saveAchievements,
  hasDailyBonusClaimed, claimDailyBonus
} from '../utils/storage';
import { LEVELS, POINTS, ACHIEVEMENTS, getLevel, getNextLevel } from '../constants/gamification';

export function useGamification(goals, getProgress) {
  const [points, setPointsState] = useState(() => loadPoints());
  const [streak, setStreakState] = useState(() => loadStreak());
  const [unlockedAchievements, setUnlockedAchievementsState] = useState(() => loadAchievements());
  const [showLevelUp, setShowLevelUp] = useState(null);
  const [showPointsPopup, setShowPointsPopup] = useState(null);
  const [dailyBonusClaimed, setDailyBonusClaimed] = useState(() => hasDailyBonusClaimed());

  // Persist state changes
  useEffect(() => {
    savePoints(points);
  }, [points]);

  useEffect(() => {
    saveStreak(streak);
  }, [streak]);

  useEffect(() => {
    saveAchievements(unlockedAchievements);
  }, [unlockedAchievements]);

  // Add points
  const addPoints = useCallback((amount, reason = '') => {
    const prevLevel = getLevel(points);
    const newPoints = points + amount;
    setPointsState(newPoints);
    
    // Show points popup
    setShowPointsPopup({ amount, reason });
    setTimeout(() => setShowPointsPopup(null), 2000);

    // Check for level up
    const newLevel = getLevel(newPoints);
    if (newLevel.level > prevLevel.level) {
      setShowLevelUp(newLevel);
    }

    return newPoints;
  }, [points]);

  // Update streak
  const updateStreak = useCallback(() => {
    const today = new Date().toDateString();
    const yesterday = new Date(Date.now() - 86400000).toDateString();

    setStreakState(prev => {
      if (prev.lastActive === today) {
        // Already updated today
        return prev;
      } else if (prev.lastActive === yesterday) {
        // Streak continues
        const newStreak = {
          current: prev.current + 1,
          best: Math.max(prev.best, prev.current + 1),
          lastActive: today
        };
        
        // Award streak bonus
        addPoints(POINTS.STREAK_BONUS * newStreak.current, `${newStreak.current}-day streak!`);
        
        return newStreak;
      } else {
        // Streak broken, start fresh
        return {
          current: 1,
          best: prev.best,
          lastActive: today
        };
      }
    });
  }, [addPoints]);

  // Claim daily bonus
  const claimBonus = useCallback(() => {
    if (dailyBonusClaimed) return false;
    
    claimDailyBonus();
    setDailyBonusClaimed(true);
    addPoints(POINTS.DAILY_BONUS, 'Daily login bonus!');
    updateStreak();
    
    return true;
  }, [dailyBonusClaimed, addPoints, updateStreak]);

  // Award points for step completion
  const awardStepPoints = useCallback(() => {
    addPoints(POINTS.STEP_COMPLETE, 'Step completed!');
    updateStreak();
  }, [addPoints, updateStreak]);

  // Award points for goal completion
  const awardGoalPoints = useCallback((isFirstGoal = false) => {
    addPoints(POINTS.GOAL_COMPLETE, 'Goal achieved!');
    if (isFirstGoal) {
      addPoints(POINTS.FIRST_GOAL, 'First goal bonus!');
    }
  }, [addPoints]);

  // Check and unlock achievements
  const checkAchievements = useCallback(() => {
    const newlyUnlocked = [];

    ACHIEVEMENTS.forEach(achievement => {
      if (unlockedAchievements.includes(achievement.id)) return;

      const unlocked = achievement.check(
        goals, 
        getProgress, 
        streak.current, 
        points,
        getLevel
      );

      if (unlocked) {
        newlyUnlocked.push(achievement);
        setUnlockedAchievementsState(prev => [...prev, achievement.id]);
      }
    });

    return newlyUnlocked;
  }, [goals, getProgress, streak.current, points, unlockedAchievements]);

  // Get current level info
  const currentLevel = getLevel(points);
  const nextLevel = getNextLevel(points);
  const levelProgress = nextLevel 
    ? Math.round(((points - currentLevel.minPoints) / (nextLevel.minPoints - currentLevel.minPoints)) * 100)
    : 100;

  return {
    points,
    streak,
    currentLevel,
    nextLevel,
    levelProgress,
    unlockedAchievements,
    showLevelUp,
    setShowLevelUp,
    showPointsPopup,
    dailyBonusClaimed,
    addPoints,
    updateStreak,
    claimBonus,
    awardStepPoints,
    awardGoalPoints,
    checkAchievements,
    allAchievements: ACHIEVEMENTS,
    allLevels: LEVELS
  };
}





