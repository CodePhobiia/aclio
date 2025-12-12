// Card Components

export function Card({ children, className = '', style = {}, onClick }) {
  return (
    <div 
      className={`card ${className} ${onClick ? 'clickable' : ''}`}
      style={style}
      onClick={onClick}
    >
      {children}
    </div>
  );
}

export function GoalCard({ goal, progress, onClick, onSwipe }) {
  const IconComponent = goal.icon;
  
  return (
    <Card 
      className="goal-card" 
      onClick={onClick}
      style={{
        '--goal-icon-bg': goal.iconBg || 'var(--accent-soft)',
        '--goal-icon-color': goal.iconColor || 'var(--accent)'
      }}
    >
      <div className="goal-card-icon">
        {IconComponent && <IconComponent />}
      </div>
      <div className="goal-card-content">
        <h3 className="goal-card-title">{goal.title}</h3>
        <div className="goal-card-meta">
          <span className="goal-card-steps">
            {goal.completedSteps?.length || 0}/{goal.steps?.length || 0} steps
          </span>
          {goal.dueDate && (
            <span className="goal-card-due">Due {new Date(goal.dueDate).toLocaleDateString()}</span>
          )}
        </div>
        <div className="goal-card-progress">
          <div className="goal-card-progress-bar">
            <div 
              className="goal-card-progress-fill" 
              style={{ width: `${progress}%` }}
            />
          </div>
          <span className="goal-card-progress-text">{progress}%</span>
        </div>
      </div>
    </Card>
  );
}

export function StepCard({ step, completed, onClick, onExpand, onDoItForMe, goalTitle }) {
  return (
    <Card 
      className={`step-card ${completed ? 'completed' : ''}`}
      onClick={onClick}
    >
      <div className="step-card-checkbox">
        {completed && <span className="step-card-check">✓</span>}
      </div>
      <div className="step-card-content">
        <div className="step-card-number">Step {step.id}</div>
        <h4 className={`step-card-title ${completed ? 'line-through' : ''}`}>
          {step.title}
        </h4>
        <p className="step-card-desc">{step.description}</p>
        {step.duration && (
          <div className="step-card-duration">
            <span>⏱</span> {step.duration}
          </div>
        )}
      </div>
    </Card>
  );
}

export function StatCard({ icon, value, label, trend, className = '' }) {
  return (
    <Card className={`stat-card ${className}`}>
      <div className="stat-card-icon">{icon}</div>
      <div className="stat-card-value">{value}</div>
      <div className="stat-card-label">{label}</div>
      {trend && (
        <div className={`stat-card-trend ${trend > 0 ? 'positive' : 'negative'}`}>
          {trend > 0 ? '+' : ''}{trend}%
        </div>
      )}
    </Card>
  );
}




