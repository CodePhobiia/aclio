// Progress Bar Component

export function ProgressBar({ percent, height = 6, showLabel = false, className = '' }) {
  return (
    <div className={`progress-bar-container ${className}`}>
      {showLabel && (
        <div className="progress-bar-label">
          <span>{Math.round(percent)}%</span>
        </div>
      )}
      <div 
        className="progress-bar-track" 
        style={{ height: `${height}px` }}
      >
        <div 
          className="progress-bar-fill" 
          style={{ 
            width: `${Math.min(100, Math.max(0, percent))}%`,
            height: '100%'
          }}
        />
      </div>
    </div>
  );
}





