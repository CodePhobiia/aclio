// Analytics Page
import { useState, useMemo } from 'react';
import { Icons } from '../constants/icons';
import { CircleProgress } from '../components/ui/CircleProgress';
import { getLevel } from '../constants/gamification';

export function AnalyticsPage({
  onNavigate,
  goals,
  getProgress,
  userPoints,
  streakData,
  unlockedAchievements,
  allAchievements,
}) {
  const [filter, setFilter] = useState('goals'); // 'goals' | 'steps'

  // Calculate analytics
  const analytics = useMemo(() => {
    const totalGoals = goals.length;
    const completedGoals = goals.filter(g => getProgress(g) === 100).length;
    const totalSteps = goals.reduce((sum, g) => sum + (g.steps?.length || 0), 0);
    const completedSteps = goals.reduce((sum, g) => sum + (g.completedSteps?.length || 0), 0);
    
    // Category breakdown
    const categories = {};
    goals.forEach(g => {
      const cat = g.category || 'Other';
      if (!categories[cat]) categories[cat] = { total: 0, completed: 0 };
      categories[cat].total++;
      if (getProgress(g) === 100) categories[cat].completed++;
    });

    // Recent activity (goals created in last 7 days)
    const weekAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
    const recentGoals = goals.filter(g => new Date(g.createdAt) > weekAgo).length;

    return {
      totalGoals,
      completedGoals,
      totalSteps,
      completedSteps,
      categories,
      recentGoals,
      overallProgress: totalSteps > 0 ? Math.round((completedSteps / totalSteps) * 100) : 0,
    };
  }, [goals, getProgress]);

  const currentLevel = getLevel(userPoints);

  return (
    <div className="app">
      <div className="analytics-page fade-in">
        {/* Header */}
        <div className="page-header">
          <button className="header-back" onClick={() => onNavigate('dashboard')}>
            <Icons.arrowLeft />
          </button>
          <h1 className="page-title">Analytics</h1>
          <div style={{width: '44px'}} />
        </div>

        <div className="analytics-content">
          {/* Overview Card */}
          <div className="analytics-overview">
            <div className="analytics-ring">
              <CircleProgress percent={analytics.overallProgress} size={100} stroke={8} />
              <div className="analytics-ring-text">
                <span className="analytics-ring-value">{analytics.overallProgress}%</span>
                <span className="analytics-ring-label">Overall</span>
              </div>
            </div>
            <div className="analytics-summary">
              <h2 className="analytics-greeting">Great progress!</h2>
              <p className="analytics-subtitle">
                You've completed {analytics.completedSteps} steps across {analytics.totalGoals} goals
              </p>
            </div>
          </div>

          {/* Stats Grid */}
          <div className="analytics-stats-grid">
            <div className="analytics-stat">
              <div className="analytics-stat-icon" style={{background: 'var(--accent-soft)', color: 'var(--accent)'}}>
                <Icons.target />
              </div>
              <div className="analytics-stat-info">
                <span className="analytics-stat-value">{analytics.totalGoals}</span>
                <span className="analytics-stat-label">Total Goals</span>
              </div>
            </div>
            <div className="analytics-stat">
              <div className="analytics-stat-icon" style={{background: 'var(--success-soft)', color: 'var(--success)'}}>
                <Icons.check />
              </div>
              <div className="analytics-stat-info">
                <span className="analytics-stat-value">{analytics.completedGoals}</span>
                <span className="analytics-stat-label">Completed</span>
              </div>
            </div>
            <div className="analytics-stat">
              <div className="analytics-stat-icon" style={{background: 'var(--purple-soft)', color: 'var(--purple)'}}>
                <Icons.activity />
              </div>
              <div className="analytics-stat-info">
                <span className="analytics-stat-value">{analytics.completedSteps}</span>
                <span className="analytics-stat-label">Steps Done</span>
              </div>
            </div>
            <div className="analytics-stat">
              <div className="analytics-stat-icon" style={{background: 'var(--orange-soft)', color: 'var(--orange)'}}>
                <Icons.flame />
              </div>
              <div className="analytics-stat-info">
                <span className="analytics-stat-value">{streakData.best}</span>
                <span className="analytics-stat-label">Best Streak</span>
              </div>
            </div>
          </div>

          {/* Level Progress */}
          <div className="analytics-section">
            <h3 className="analytics-section-title">Your Level</h3>
            <div className="analytics-level-card">
              <div className="analytics-level-header">
                <div className="analytics-level-badge">
                  {(() => {
                    const LevelIcon = Icons[currentLevel.icon] || Icons.star;
                    return <LevelIcon />;
                  })()}
                </div>
                <div className="analytics-level-info">
                  <span className="analytics-level-name">{currentLevel.name}</span>
                  <span className="analytics-level-number">Level {currentLevel.level}</span>
                </div>
                <div className="analytics-level-points">
                  <span className="analytics-points-value">{userPoints}</span>
                  <span className="analytics-points-label">XP</span>
                </div>
              </div>
            </div>
          </div>

          {/* Achievements */}
          <div className="analytics-section">
            <h3 className="analytics-section-title">
              Achievements ({unlockedAchievements.length}/{allAchievements.length})
            </h3>
            <div className="analytics-achievements-grid">
              {allAchievements.map(achievement => {
                const isUnlocked = unlockedAchievements.includes(achievement.id);
                const AchIcon = Icons[achievement.icon] || Icons.star;
                return (
                  <div 
                    key={achievement.id} 
                    className={`analytics-achievement ${isUnlocked ? 'unlocked' : 'locked'}`}
                    style={{background: isUnlocked ? achievement.gradient : 'var(--bg-card)'}}
                  >
                    <div className="analytics-achievement-icon">
                      <AchIcon />
                    </div>
                    <span className="analytics-achievement-name">{achievement.name}</span>
                    <span className="analytics-achievement-desc">{achievement.desc}</span>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Completed Goals */}
          {analytics.completedGoals > 0 && (
            <div className="analytics-section">
              <h3 className="analytics-section-title">Completed Goals</h3>
              <div className="analytics-completed-list">
                {goals.filter(g => getProgress(g) === 100).map(goal => {
                  const IconComponent = Icons[goal.iconKey] || Icons.target;
                  return (
                    <div key={goal.id} className="analytics-completed-item">
                      <div 
                        className="analytics-completed-icon"
                        style={{
                          background: goal.iconColor?.bg || 'var(--accent-soft)',
                          color: goal.iconColor?.color || 'var(--accent)'
                        }}
                      >
                        <IconComponent />
                      </div>
                      <div className="analytics-completed-info">
                        <span className="analytics-completed-name">{goal.name}</span>
                        <span className="analytics-completed-steps">
                          {goal.steps?.length} steps completed
                        </span>
                      </div>
                      <div className="analytics-completed-badge">
                        <Icons.check /> Done
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

