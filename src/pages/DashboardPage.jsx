// Dashboard Page
import { useState, useRef } from 'react';
import { Icons } from '../constants/icons';
import { PREMIUM_CONFIG } from '../constants/config';
import { POINTS, getLevel, getNextLevel } from '../constants/gamification';
import { CircleProgress } from '../components/ui/CircleProgress';

export function DashboardPage({
  // Navigation
  onNavigate,
  // Profile
  profile,
  getGreeting,
  // Goals
  goals,
  getProgress,
  toggleStep,
  deleteGoal,
  setActiveGoal,
  searchQuery,
  setSearchQuery,
  // Theme
  theme,
  toggleTheme,
  // Premium
  isPremium,
  setShowPaywall,
  handlePremiumFeature,
  // Gamification
  userPoints,
  streakData,
  dailyBonusClaimed,
  claimDailyBonus,
  showPointsPopup,
  showLevelUp,
  setShowLevelUp,
}) {
  const dashboardRef = useRef(null);
  const [pullDistance, setPullDistance] = useState(0);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [swipingGoalId, setSwipingGoalId] = useState(null);
  const [swipeX, setSwipeX] = useState(0);
  const startY = useRef(0);
  const startX = useRef(0);

  // Get today's focus tasks (first incomplete step from each goal)
  const todayTasks = goals
    .filter(g => getProgress(g) < 100)
    .map(g => {
      const next = g.steps?.find(s => !g.completedSteps?.includes(s.id));
      return next ? { ...next, goalId: g.id, goalName: g.name } : null;
    })
    .filter(Boolean)
    .slice(0, 3);

  // Filter goals by search
  const filteredGoals = goals.filter(g => {
    if (!searchQuery) return getProgress(g) < 100;
    const q = searchQuery.toLowerCase();
    return g.name?.toLowerCase().includes(q) || 
           g.steps?.some(s => s.title?.toLowerCase().includes(q));
  });

  // Get next step for a goal
  const getNextStep = (goal) => {
    return goal.steps?.find(s => !goal.completedSteps?.includes(s.id));
  };

  // Get due date status
  const getDueDateStatus = (dueDate) => {
    if (!dueDate) return null;
    const due = new Date(dueDate);
    const today = new Date();
    const diffDays = Math.ceil((due - today) / (1000 * 60 * 60 * 24));
    
    if (diffDays < 0) return { status: 'overdue', text: 'Overdue' };
    if (diffDays === 0) return { status: 'today', text: 'Due today' };
    if (diffDays <= 3) return { status: 'soon', text: `${diffDays}d left` };
    return { status: 'normal', text: `${diffDays}d left` };
  };

  // Pull to refresh handlers
  const handlePullStart = (e) => { startY.current = e.touches[0].clientY; };
  const handlePullMove = (e) => {
    if (dashboardRef.current?.scrollTop > 0) return;
    const diff = e.touches[0].clientY - startY.current;
    if (diff > 0) setPullDistance(Math.min(diff * 0.5, 80));
  };
  const handlePullEnd = () => {
    if (pullDistance > 60) {
      setIsRefreshing(true);
      setTimeout(() => { setIsRefreshing(false); setPullDistance(0); }, 1000);
    } else {
      setPullDistance(0);
    }
  };

  // Swipe handlers for goal cards
  const handleSwipeStart = (e, goalId) => {
    startX.current = e.touches[0].clientX;
    setSwipingGoalId(goalId);
  };
  const handleSwipeMove = (e, goalId) => {
    if (swipingGoalId !== goalId) return;
    const diff = startX.current - e.touches[0].clientX;
    setSwipeX(Math.max(0, Math.min(diff, 80)));
  };
  const handleSwipeEnd = (goalId) => {
    if (swipeX > 50) {
      if (confirm('Delete this goal?')) deleteGoal(goalId);
    }
    setSwipeX(0);
    setSwipingGoalId(null);
  };

  // Level info
  const currentLevel = getLevel(userPoints);
  const nextLevel = getNextLevel(userPoints);
  const LevelIcon = Icons[currentLevel.icon] || Icons.star;
  const progressToNext = nextLevel 
    ? ((userPoints - currentLevel.minPoints) / (nextLevel.minPoints - currentLevel.minPoints)) * 100
    : 100;

  return (
    <div className="app">
      <div 
        className="dashboard fade-in" 
        ref={dashboardRef}
        onTouchStart={handlePullStart}
        onTouchMove={handlePullMove}
        onTouchEnd={handlePullEnd}
      >
        {/* Dark Hero Section */}
        <div className="dashboard-hero">
          {/* Pull to Refresh Indicator */}
          <div className={`pull-refresh-indicator ${pullDistance > 20 || isRefreshing ? 'visible' : ''} ${isRefreshing ? 'refreshing' : ''}`}>
            <Icons.refreshCw className="pull-refresh-icon" />
            <span>{isRefreshing ? 'Refreshing...' : pullDistance > 60 ? 'Release to refresh' : 'Pull to refresh'}</span>
          </div>
          
          <div className="greeting-section">
            <p className="greeting-text">{getGreeting?.() || 'Hello'}, {profile?.name || 'Achiever'}!</p>
            <p className="greeting-subtitle">Let's make progress on your goals today.</p>
          </div>
          
          <button className="hero-cta" onClick={() => handlePremiumFeature('goal', () => onNavigate('new'))}>
            <Icons.plus style={{width: '20px', height: '20px'}} /> Create New Goal
          </button>
          
          {/* Header icons */}
          <div style={{position: 'absolute', top: 'calc(var(--safe-top) + 16px)', right: '16px', display: 'flex', gap: '8px'}}>
            <button className="header-icon" style={{color: 'rgba(255,255,255,0.8)', background: 'rgba(255,255,255,0.1)'}} onClick={toggleTheme}>
              {theme === 'dark' ? <Icons.sun /> : <Icons.moon />}
            </button>
            <button className="header-icon" style={{color: 'rgba(255,255,255,0.8)', background: 'rgba(255,255,255,0.1)'}} onClick={() => onNavigate('analytics')}>
              <Icons.barChart />
            </button>
            <button className="header-icon" style={{color: 'rgba(255,255,255,0.8)', background: 'rgba(255,255,255,0.1)'}} onClick={() => onNavigate('settings')}>
              <Icons.settings />
            </button>
          </div>
        </div>
        
        {/* Dashboard Content */}
        <div className="dashboard-content">
          {/* Premium Banner with Mascot */}
          {!isPremium && (
            <div className="premium-banner" onClick={() => setShowPaywall(true)}>
              <img 
                src="/Mascot face Icon.png" 
                alt="Aclio mascot" 
                className="premium-banner-mascot"
              />
              <div className="premium-banner-content">
                <span className="premium-banner-title">Go Premium</span>
                <p className="premium-banner-desc">3-day free trial</p>
              </div>
              <button className="premium-banner-btn" onClick={(e) => { e.stopPropagation(); setShowPaywall(true); }}>
                Start free trial
              </button>
            </div>
          )}
          
          {/* Search Bar */}
          <div className="search-bar">
            <Icons.search />
            <input 
              className="search-input" 
              placeholder="Search goals..." 
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
            {searchQuery && (
              <button className="search-clear" onClick={() => setSearchQuery('')}>
                <Icons.x />
              </button>
            )}
          </div>

          {/* Today's Focus */}
          {todayTasks.length > 0 && (
            <div className="section">
              <div className="focus-card">
                <div className="focus-header">
                  <span className="focus-icon" style={{color: 'var(--accent)'}}><Icons.sparkles /></span>
                  <span className="focus-title">Today's Focus</span>
                </div>
                {todayTasks.map(task => {
                  const goal = goals.find(g => g.id === task.goalId);
                  const isDone = goal?.completedSteps?.includes(task.id);
                  return (
                    <div key={`${task.goalId}-${task.id}`} className="focus-item" onClick={() => toggleStep(task.goalId, task.id)}>
                      <div className={`focus-check ${isDone ? 'checked' : ''}`}>{isDone && <Icons.check />}</div>
                      <div className="focus-content">
                        <p className={`focus-task ${isDone ? 'done' : ''}`}>{task.title}</p>
                        <p className="focus-goal">{task.goalName}</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Active Goals */}
          <div className="section">
            <div className="section-header">
              <h2 className="section-title">Active Goals</h2>
            </div>

            {filteredGoals.length > 0 ? filteredGoals.map((goal, i) => {
              const progress = getProgress(goal);
              const next = getNextStep(goal);
              const iconBg = goal.iconColor?.bg || 'var(--accent-soft)';
              const iconColor = goal.iconColor?.color || 'var(--accent)';
              const IconComponent = Icons[goal.iconKey] || Icons.target;
              const dueDateInfo = getDueDateStatus(goal.dueDate);
              const isSwiping = swipingGoalId === goal.id;
              
              return (
                <div key={goal.id} className="goal-card-wrapper slide-up" style={{animationDelay: `${i * 0.1}s`}}>
                  <div className="goal-card-delete" onClick={() => { if(confirm('Delete this goal?')) deleteGoal(goal.id); }}>
                    <Icons.trash />
                  </div>
                  <div 
                    className={`goal-card ${isSwiping ? 'swiping' : ''}`}
                    style={{transform: isSwiping ? `translateX(-${swipeX}px)` : 'translateX(0)'}}
                    onClick={() => { if (!isSwiping || swipeX < 10) { setActiveGoal(goal); onNavigate('detail'); } }}
                    onTouchStart={(e) => handleSwipeStart(e, goal.id)}
                    onTouchMove={(e) => handleSwipeMove(e, goal.id)}
                    onTouchEnd={() => handleSwipeEnd(goal.id)}
                  >
                    <div className="goal-header">
                      <div className="goal-icon-wrap" style={{background: iconBg, color: iconColor}}>
                        <IconComponent />
                      </div>
                      <div className="goal-info">
                        <h3 className="goal-name">{goal.name}</h3>
                        <p className="goal-category">{goal.category || 'Personal Goal'}</p>
                        {dueDateInfo && (
                          <div className={`due-date-badge ${dueDateInfo.status}`}>
                            <Icons.calendar /> {dueDateInfo.text}
                          </div>
                        )}
                      </div>
                    </div>
                    <div className="goal-progress-row">
                      <span className="goal-progress-label">Progress</span>
                      <span className="goal-progress-value">{progress}%</span>
                    </div>
                    <div className="goal-progress-bar">
                      <div className="goal-progress-fill" style={{width: `${progress}%`}} />
                    </div>
                    {next && (
                      <div className="goal-next">
                        <span className="goal-next-arrow"><Icons.arrowRight /></span>
                        <span className="goal-next-text">{next.title}</span>
                      </div>
                    )}
                  </div>
                </div>
              );
            }) : (
              <div className="empty-state">
                <div className="empty-emoji" style={{color: 'var(--accent)'}}>
                  {searchQuery ? <Icons.search /> : <Icons.target />}
                </div>
                <h3 className="empty-title">{searchQuery ? 'No goals found' : 'No goals yet'}</h3>
                <p className="empty-text">
                  {searchQuery 
                    ? `No goals match "${searchQuery}". Try a different search.`
                    : 'Tap "New Goal" to set your first goal and let AI create your action plan!'}
                </p>
              </div>
            )}
          </div>

          {/* Level Card */}
          {!searchQuery && (
            <div className="level-card">
              <div className="level-header">
                <div className="level-info">
                  <div className="level-badge"><LevelIcon /></div>
                  <div>
                    <p className="level-number">Level {currentLevel.level}</p>
                    <h3 className="level-title">{currentLevel.name}</h3>
                  </div>
                </div>
                <div className="level-points">
                  <p className="level-points-value">{userPoints}</p>
                  <p className="level-points-label">points</p>
                </div>
              </div>
              <div className="level-progress">
                <div className="level-progress-bar">
                  <div className="level-progress-fill" style={{width: `${progressToNext}%`}} />
                </div>
                <div className="level-progress-text">
                  <span>{currentLevel.minPoints} XP</span>
                  <span>{nextLevel ? `${nextLevel.minPoints} XP` : 'MAX'}</span>
                </div>
              </div>
            </div>
          )}
          
          {/* Daily Bonus */}
          {!searchQuery && !dailyBonusClaimed && (
            <div className="daily-bonus-card" onClick={claimDailyBonus}>
              <div className="daily-bonus-icon"><Icons.coins /></div>
              <div className="daily-bonus-info">
                <p className="daily-bonus-title">Daily Bonus Available!</p>
                <p className="daily-bonus-desc">Claim +{POINTS.DAILY_BONUS} points</p>
              </div>
              <button className="daily-bonus-btn">Claim</button>
            </div>
          )}
          
          {/* Streak Card */}
          {!searchQuery && (
            <div className="streak-card">
              <div className="streak-header">
                <div className="streak-info">
                  <div className="streak-icon"><Icons.flame /></div>
                  <div>
                    <p className="streak-label">Current Streak</p>
                    <p className="streak-value">{streakData.current} day{streakData.current !== 1 ? 's' : ''}</p>
                  </div>
                </div>
                <div className="streak-best">
                  <p className="streak-best-label">Best</p>
                  <p className="streak-best-value">{streakData.best} days</p>
                </div>
              </div>
              <div className="streak-days">
                {[...Array(7)].map((_, i) => {
                  const isActive = i < streakData.current;
                  const isToday = i === streakData.current - 1 || (streakData.current === 0 && i === 0);
                  return (
                    <div 
                      key={i} 
                      className={`streak-day ${isActive ? 'active' : ''} ${isToday && streakData.current > 0 ? 'today' : ''}`} 
                    />
                  );
                })}
              </div>
            </div>
          )}

          {/* Progress Hub */}
          {!searchQuery && (
            <div className="progress-hub" style={{marginTop: 'var(--section-gap)'}}>
              <h3 className="progress-hub-title">Progress Hub</h3>
              <div className="progress-hub-badges">
                <div className="progress-badge streak">
                  <span>🔥</span>
                  <span>{streakData.current}-day streak</span>
                </div>
                <div className="progress-badge level">
                  <span>⭐</span>
                  <span>Level {currentLevel.level} Achiever</span>
                </div>
              </div>
            </div>
          )}
          
          {/* Achievement Cards */}
          {!searchQuery && (
            <div className="achievements-row">
              <div className="achievement-card purple">
                <span className="achievement-card-icon">🏆</span>
                <span className="achievement-card-label">Goal Setter</span>
              </div>
              <div className="achievement-card teal">
                <span className="achievement-card-icon">⚡</span>
                <span className="achievement-card-label">Streak Champion</span>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* FAB */}
      <button className="fab" onClick={() => handlePremiumFeature('goal', () => onNavigate('new'))}>
        <span className="fab-icon"><Icons.plus /></span> New Goal
        {!isPremium && goals.length >= PREMIUM_CONFIG.FREE_GOAL_LIMIT - 1 && goals.length < PREMIUM_CONFIG.FREE_GOAL_LIMIT && (
          <span style={{marginLeft: '8px', fontSize: '11px', opacity: 0.8}}>({PREMIUM_CONFIG.FREE_GOAL_LIMIT - goals.length} left)</span>
        )}
      </button>
      
      {/* Points Popup */}
      {showPointsPopup && (
        <div className="points-popup">
          <Icons.coins /> {showPointsPopup.reason}
        </div>
      )}
      
      {/* Level Up Modal */}
      {showLevelUp && (
        <div className="levelup-modal" onClick={() => setShowLevelUp(null)}>
          <div className="levelup-card fade-in" onClick={e => e.stopPropagation()}>
            <div className="levelup-icon">
              {(() => {
                const LevelUpIcon = Icons[showLevelUp.icon] || Icons.star;
                return <LevelUpIcon />;
              })()}
            </div>
            <h2 className="levelup-title">Level Up!</h2>
            <p className="levelup-level">You reached Level {showLevelUp.level}: {showLevelUp.name}</p>
            <div className="levelup-rewards">
              <div className="levelup-reward">
                <Icons.trophy /> New title unlocked!
              </div>
            </div>
            <button className="levelup-btn" onClick={() => setShowLevelUp(null)}>
              Awesome!
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

