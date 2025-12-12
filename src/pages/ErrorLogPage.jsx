// Error Log Page
import { useState } from 'react';
import { Icons } from '../constants/icons';
import { ErrorTracker } from '../utils/errorTracker';

export function ErrorLogPage({ onNavigate }) {
  const [filter, setFilter] = useState('all');
  const [expandedError, setExpandedError] = useState(null);
  const [stats, setStats] = useState(ErrorTracker.getStats());

  const errors = ErrorTracker.getErrors(filter);

  const handleClear = () => {
    if (confirm('Clear all error logs?')) {
      ErrorTracker.clear();
      setStats(ErrorTracker.getStats());
    }
  };

  const handleExport = () => {
    const data = ErrorTracker.export();
    const blob = new Blob([data], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `aclio-errors-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const formatTime = (timestamp) => {
    const date = new Date(timestamp);
    return date.toLocaleString();
  };

  return (
    <div className="app">
      <div className="error-log-page fade-in">
        {/* Header */}
        <div className="page-header">
          <button className="header-back" onClick={() => onNavigate('settings')}>
            <Icons.arrowLeft />
          </button>
          <h1 className="page-title">Error Log</h1>
          <button className="header-icon" onClick={handleExport}>
            <Icons.download />
          </button>
        </div>

        <div className="error-log-content">
          {/* Stats */}
          <div className="error-stats">
            <div className="error-stat">
              <span className="error-stat-value">{stats.total}</span>
              <span className="error-stat-label">Total</span>
            </div>
            <div className="error-stat error">
              <span className="error-stat-value">{stats.errors}</span>
              <span className="error-stat-label">Errors</span>
            </div>
            <div className="error-stat warning">
              <span className="error-stat-value">{stats.warnings}</span>
              <span className="error-stat-label">Warnings</span>
            </div>
            <div className="error-stat info">
              <span className="error-stat-value">{stats.info}</span>
              <span className="error-stat-label">Info</span>
            </div>
          </div>

          {/* Filters */}
          <div className="error-filters">
            {['all', 'error', 'warning', 'info'].map(f => (
              <button
                key={f}
                className={`error-filter-btn ${filter === f ? 'active' : ''}`}
                onClick={() => setFilter(f)}
              >
                {f.charAt(0).toUpperCase() + f.slice(1)}
              </button>
            ))}
          </div>

          {/* Error List */}
          <div className="error-list">
            {errors.length === 0 ? (
              <div className="empty-state">
                <Icons.check />
                <h3>No errors</h3>
                <p>Your app is running smoothly!</p>
              </div>
            ) : (
              errors.map(error => (
                <div 
                  key={error.id} 
                  className={`error-item ${error.type}`}
                  onClick={() => setExpandedError(expandedError === error.id ? null : error.id)}
                >
                  <div className="error-item-header">
                    <div className={`error-type-badge ${error.type}`}>
                      {error.type === 'error' && <Icons.alertTriangle />}
                      {error.type === 'warning' && <Icons.info />}
                      {error.type === 'info' && <Icons.info />}
                      {error.type}
                    </div>
                    <span className="error-time">{formatTime(error.context?.timestamp)}</span>
                  </div>
                  <p className="error-message">{error.message}</p>
                  
                  {expandedError === error.id && (
                    <div className="error-details">
                      {error.stack && (
                        <div className="error-stack">
                          <strong>Stack:</strong>
                          <pre>{error.stack}</pre>
                        </div>
                      )}
                      <div className="error-context">
                        <strong>Context:</strong>
                        <pre>{JSON.stringify(error.context, null, 2)}</pre>
                      </div>
                    </div>
                  )}
                </div>
              ))
            )}
          </div>

          {/* Clear Button */}
          {errors.length > 0 && (
            <button className="error-clear-btn" onClick={handleClear}>
              <Icons.trash /> Clear All Logs
            </button>
          )}
        </div>
      </div>
    </div>
  );
}




