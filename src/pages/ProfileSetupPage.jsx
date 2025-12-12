// Profile Setup Page
import { useState } from 'react';

export function ProfileSetupPage({ profile, onProfileChange, onComplete, onSkip }) {
  const [localProfile, setLocalProfile] = useState(profile);
  
  const canContinue = localProfile.name.trim();

  const handleChange = (field, value) => {
    setLocalProfile(prev => ({ ...prev, [field]: value }));
  };

  const handleSubmit = () => {
    onProfileChange(localProfile);
    onComplete();
  };

  return (
    <div className="app app-no-scroll">
      <div className="profile-setup fade-in">
        <button className="onboarding-skip-top" onClick={onSkip}>
          Skip
        </button>
        
        <div className="profile-header">
          <h1 className="profile-title">Tell us about yourself</h1>
          <p className="profile-subtitle">This helps us personalize your experience</p>
        </div>

        <div className="profile-form">
          <div className="profile-field">
            <label className="profile-label">Your Name *</label>
            <input
              className="profile-input"
              type="text"
              placeholder="e.g., Theyab"
              value={localProfile.name}
              onChange={(e) => handleChange('name', e.target.value)}
              autoFocus
            />
          </div>

          <div className="profile-field">
            <label className="profile-label">Your Age</label>
            <input
              className="profile-input"
              type="number"
              placeholder="e.g., 22"
              value={localProfile.age}
              onChange={(e) => handleChange('age', e.target.value)}
            />
          </div>

          <div className="profile-field">
            <label className="profile-label">Gender</label>
            <div className="profile-gender-options">
              {['Male', 'Female', 'Other'].map(option => (
                <button
                  key={option}
                  className={`profile-gender-btn ${localProfile.gender === option ? 'selected' : ''}`}
                  onClick={() => handleChange('gender', option)}
                >
                  {option}
                </button>
              ))}
            </div>
          </div>
        </div>

        <div className="profile-submit">
          <button 
            className="primary-btn" 
            onClick={handleSubmit}
            disabled={!canContinue}
            style={{ opacity: canContinue ? 1 : 0.5 }}
          >
            Continue
          </button>
        </div>
      </div>
    </div>
  );
}




