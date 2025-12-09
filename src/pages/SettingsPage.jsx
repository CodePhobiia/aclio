// Settings Page
import { Icons } from '../constants/icons';

export function SettingsPage({
  onNavigate,
  profile,
  theme,
  toggleTheme,
  notificationsEnabled,
  setNotificationsEnabled,
  location,
  locationLoading,
  fetchLocation,
  clearLocation,
  isPremium,
  setShowPaywall,
  onLogout,
}) {
  return (
    <div className="app">
      <div className="settings-page fade-in">
        {/* Header */}
        <div className="page-header">
          <button className="header-back" onClick={() => onNavigate('dashboard')}>
            <Icons.arrowLeft />
          </button>
          <h1 className="page-title">Settings</h1>
          <div style={{width: '44px'}} />
        </div>

        <div className="settings-content">
          {/* Profile Section */}
          <div className="settings-section">
            <h2 className="settings-section-title">Profile</h2>
            <div className="settings-card">
              <div className="settings-item" onClick={() => onNavigate('edit-profile')}>
                <div className="settings-item-icon">
                  <Icons.user />
                </div>
                <div className="settings-item-content">
                  <span className="settings-item-label">Edit Profile</span>
                  <span className="settings-item-value">{profile?.name || 'Not set'}</span>
                </div>
                <Icons.chevronRight />
              </div>
            </div>
          </div>

          {/* Preferences Section */}
          <div className="settings-section">
            <h2 className="settings-section-title">Preferences</h2>
            <div className="settings-card">
              {/* Theme Toggle */}
              <div className="settings-item" onClick={toggleTheme}>
                <div className="settings-item-icon">
                  {theme === 'dark' ? <Icons.moon /> : <Icons.sun />}
                </div>
                <div className="settings-item-content">
                  <span className="settings-item-label">Dark Mode</span>
                  <span className="settings-item-value">{theme === 'dark' ? 'On' : 'Off'}</span>
                </div>
                <div className={`settings-toggle ${theme === 'dark' ? 'active' : ''}`} />
              </div>

              {/* Notifications */}
              <div className="settings-item" onClick={() => setNotificationsEnabled(!notificationsEnabled)}>
                <div className="settings-item-icon">
                  <Icons.bell />
                </div>
                <div className="settings-item-content">
                  <span className="settings-item-label">Notifications</span>
                  <span className="settings-item-value">{notificationsEnabled ? 'On' : 'Off'}</span>
                </div>
                <div className={`settings-toggle ${notificationsEnabled ? 'active' : ''}`} />
              </div>

              {/* Location */}
              <div className="settings-item" onClick={location ? clearLocation : fetchLocation}>
                <div className="settings-item-icon">
                  <Icons.mapPin />
                </div>
                <div className="settings-item-content">
                  <span className="settings-item-label">Location</span>
                  <span className="settings-item-value">
                    {locationLoading ? 'Getting location...' : (location?.city || 'Not set')}
                  </span>
                </div>
                {location ? <Icons.x /> : <Icons.chevronRight />}
              </div>
            </div>
          </div>

          {/* Premium Section */}
          <div className="settings-section">
            <h2 className="settings-section-title">Subscription</h2>
            <div className="settings-card">
              <div className="settings-item" onClick={() => !isPremium && setShowPaywall(true)}>
                <div className="settings-item-icon premium">
                  <Icons.crown />
                </div>
                <div className="settings-item-content">
                  <span className="settings-item-label">Premium Status</span>
                  <span className="settings-item-value">
                    {isPremium ? 'Active' : 'Free Plan'}
                  </span>
                </div>
                {!isPremium && <Icons.chevronRight />}
              </div>
            </div>
          </div>

          {/* Data Section */}
          <div className="settings-section">
            <h2 className="settings-section-title">Data & Privacy</h2>
            <div className="settings-card">
              <div className="settings-item" onClick={() => onNavigate('analytics')}>
                <div className="settings-item-icon">
                  <Icons.barChart />
                </div>
                <div className="settings-item-content">
                  <span className="settings-item-label">Analytics</span>
                </div>
                <Icons.chevronRight />
              </div>

              <div className="settings-item" onClick={() => onNavigate('error-log')}>
                <div className="settings-item-icon">
                  <Icons.bug />
                </div>
                <div className="settings-item-content">
                  <span className="settings-item-label">Error Log</span>
                </div>
                <Icons.chevronRight />
              </div>
            </div>
          </div>

          {/* About Section */}
          <div className="settings-section">
            <h2 className="settings-section-title">About</h2>
            <div className="settings-card">
              <div className="settings-item">
                <div className="settings-item-icon">
                  <Icons.info />
                </div>
                <div className="settings-item-content">
                  <span className="settings-item-label">Version</span>
                  <span className="settings-item-value">2.0.0</span>
                </div>
              </div>

              <a 
                href="https://thecribbusiness.github.io/aclio/privacy-policy.html" 
                target="_blank" 
                rel="noopener noreferrer"
                className="settings-item"
              >
                <div className="settings-item-icon">
                  <Icons.shield />
                </div>
                <div className="settings-item-content">
                  <span className="settings-item-label">Privacy Policy</span>
                </div>
                <Icons.externalLink />
              </a>

              <a 
                href="https://thecribbusiness.github.io/aclio/terms-of-service.html" 
                target="_blank" 
                rel="noopener noreferrer"
                className="settings-item"
              >
                <div className="settings-item-icon">
                  <Icons.fileText />
                </div>
                <div className="settings-item-content">
                  <span className="settings-item-label">Terms of Service</span>
                </div>
                <Icons.externalLink />
              </a>
            </div>
          </div>

          {/* Logout */}
          <div className="settings-section">
            <button className="logout-btn" onClick={onLogout}>
              <Icons.logout /> Sign Out
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

