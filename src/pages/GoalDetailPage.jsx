// Goal Detail Page
import { useState } from 'react';
import { Icons } from '../constants/icons';
import { CircleProgress } from '../components/ui/CircleProgress';

export function GoalDetailPage({
  goal,
  onNavigate,
  toggleStep,
  deleteGoal,
  getProgress,
  onExpandStep,
  onDoItForMe,
  expandedSteps,
  isPremium,
  canExpandStep,
  canUseDoItForMe,
  setShowPaywall,
  showCelebration,
  setShowCelebration,
}) {
  const [expandingStep, setExpandingStep] = useState(null);
  const [doingItForMe, setDoingItForMe] = useState(null);

  if (!goal) {
    return (
      <div className="app">
        <div className="page-header">
          <button className="header-back" onClick={() => onNavigate('dashboard')}>
            <Icons.arrowLeft />
          </button>
          <h1 className="page-title">Goal not found</h1>
        </div>
      </div>
    );
  }

  const progress = getProgress(goal);
  const IconComponent = Icons[goal.iconKey] || Icons.target;
  const iconBg = goal.iconColor?.bg || 'var(--accent-soft)';
  const iconColor = goal.iconColor?.color || 'var(--accent)';

  const handleToggleStep = (stepId) => {
    const wasCompleted = goal.completedSteps?.includes(stepId);
    toggleStep(goal.id, stepId);
    
    // Check if this completes the goal
    if (!wasCompleted) {
      const newCompletedCount = (goal.completedSteps?.length || 0) + 1;
      if (newCompletedCount === goal.steps.length) {
        setShowCelebration(true);
      }
    }
  };

  const handleExpandStep = async (step) => {
    if (!canExpandStep()) {
      setShowPaywall(true);
      return;
    }
    
    setExpandingStep(step.id);
    await onExpandStep(step, goal);
    setExpandingStep(null);
  };

  const handleDoItForMe = async (step) => {
    if (!canUseDoItForMe()) {
      setShowPaywall(true);
      return;
    }
    
    setDoingItForMe(step.id);
    await onDoItForMe(step, goal);
    setDoingItForMe(null);
  };

  const handleDelete = () => {
    if (confirm('Are you sure you want to delete this goal?')) {
      deleteGoal(goal.id);
      onNavigate('dashboard');
    }
  };

  return (
    <div className="app">
      {/* Header */}
      <div className="header">
        <div className="header-left">
          <button className="header-back" onClick={() => onNavigate('dashboard')}>
            <Icons.arrowLeft />
          </button>
          <span className="header-title">Goal Details</span>
        </div>
        <button className="header-icon" onClick={handleDelete}>
          <Icons.trash />
        </button>
      </div>

      <div className="detail-view fade-in">
        {/* Goal Card */}
        <div className="detail-card">
          <div className="detail-header">
            <div className="detail-icon" style={{background: iconBg, color: iconColor}}>
              <IconComponent />
            </div>
            <div className="detail-info">
              <h1 className="detail-name">{goal.name}</h1>
              {goal.category && <p className="detail-meta">{goal.category}</p>}
              {goal.dueDate && (
                <div className="detail-time-range">
                  <Icons.calendar style={{ width: 14, height: 14, marginRight: 4, verticalAlign: 'middle' }} />
                  Due: {new Date(goal.dueDate).toLocaleDateString()}
                </div>
              )}
            </div>
          </div>

          {/* Progress Section */}
          <div className="detail-progress">
            <div className="detail-progress-circle">
              <CircleProgress percent={progress} size={56} stroke={6} />
              <div className="detail-progress-text">{progress}%</div>
            </div>
            <div className="detail-progress-info">
              <div className="detail-progress-label">PROGRESS</div>
              <div className="detail-progress-value">
                {goal.completedSteps?.length || 0} of {goal.steps?.length} steps completed
              </div>
            </div>
          </div>
        </div>

        {/* Talk to Aclio Card */}
        <div className="talk-to-aclio-card" onClick={() => onNavigate('chat', { goalId: goal.id })}>
          <div className="talk-to-aclio-mascot">
            <img src="/Mascot face Icon.png" alt="Aclio" />
          </div>
          <div className="talk-to-aclio-content">
            <h3 className="talk-to-aclio-title">Talk to Aclio</h3>
            <p className="talk-to-aclio-desc">Get personalized advice and motivation for this goal</p>
          </div>
          <div className="talk-to-aclio-arrow">
            <Icons.chevronRight />
          </div>
        </div>

        {/* Steps Section */}
        <h3 className="action-steps-title">Action Steps</h3>
        
        <div className="steps-list">
          {goal.steps?.map((step, i) => {
            const isCompleted = goal.completedSteps?.includes(step.id);
            const isExpanded = expandedSteps?.[`${goal.id}-${step.id}`];
            const isExpanding = expandingStep === step.id;
            const isDoingIt = doingItForMe === step.id;

            return (
              <div 
                key={step.id} 
                className={`step-item ${isCompleted ? 'done' : ''}`}
                style={{animationDelay: `${i * 0.05}s`}}
              >
                <div 
                  className="step-check" 
                  onClick={() => handleToggleStep(step.id)}
                >
                  {isCompleted && <Icons.check />}
                </div>
                
                <div className="step-body">
                  <h3 className="step-title">
                    <span className="step-title-prefix">Step {step.id}: </span>
                    {step.title}
                  </h3>
                  <p className="step-desc">{step.description}</p>
                  
                  {step.duration && (
                    <div className="step-meta-row">
                      <div className="step-dur">
                        <Icons.clock /> {step.duration}
                      </div>
                    </div>
                  )}

                  {/* Expanded Content */}
                  {isExpanded && (
                    <div className="step-expanded" style={{
                      marginTop: '12px',
                      padding: '12px',
                      background: 'var(--bg)',
                      borderRadius: '8px',
                      fontSize: '14px',
                      lineHeight: '1.6',
                      color: 'var(--text-secondary)'
                    }}>
                      {isExpanded.content}
                    </div>
                  )}

                  {/* Step Actions */}
                  {!isCompleted && (
                    <div className="step-actions-row">
                      <button 
                        className={`step-action-btn expand ${isExpanded ? 'done' : ''}`}
                        onClick={() => handleExpandStep(step)}
                        disabled={isExpanding}
                      >
                        {isExpanding ? (
                          <Icons.refresh className="spin" />
                        ) : (
                          <><Icons.expand /> Expand</>
                        )}
                      </button>
                      <button 
                        className="step-action-btn doitforme"
                        onClick={() => handleDoItForMe(step)}
                        disabled={isDoingIt}
                      >
                        {isDoingIt ? (
                          <Icons.refresh className="spin" />
                        ) : (
                          <><Icons.wand /> Do it for me</>
                        )}
                      </button>
                    </div>
                  )}
                </div>
                
                {isCompleted && (
                  <div className="step-done-icon">
                    <Icons.check />
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {/* Delete Button */}
        <button className="delete-btn" onClick={handleDelete}>
          <Icons.trash style={{ width: 16, height: 16, marginRight: 8 }} />
          Delete Goal
        </button>
      </div>

      {/* Celebration Modal */}
      {showCelebration && (
        <div className="celebration-modal" onClick={() => setShowCelebration(false)}>
          <div className="celebration-content" onClick={e => e.stopPropagation()}>
            <div className="celebration-emoji">🎉</div>
            <h2 className="celebration-title">Goal Achieved!</h2>
            <p className="celebration-text">
              Congratulations! You've completed all steps for "{goal.name}". 
              You're amazing!
            </p>
            <div className="celebration-actions">
              <button 
                className="modal-btn secondary" 
                onClick={() => { setShowCelebration(false); onNavigate('dashboard'); }}
              >
                Back to Dashboard
              </button>
              <button 
                className="modal-btn primary"
                onClick={() => setShowCelebration(false)}
              >
                View Goal
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

