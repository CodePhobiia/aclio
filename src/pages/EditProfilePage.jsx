// Edit Profile Page
import { useState } from 'react';
import { Icons } from '../constants/icons';

export function EditProfilePage({ profile, onSave, onNavigate }) {
  const [localProfile, setLocalProfile] = useState(profile || { name: '', age: '', gender: '' });

  const handleChange = (field, value) => {
    setLocalProfile(prev => ({ ...prev, [field]: value }));
  };

  const handleSave = () => {
    onSave(localProfile);
    onNavigate('settings');
  };

  return (
    <div className="app">
      <div className="edit-profile-page fade-in">
        {/* Header */}
        <div className="page-header">
          <button className="header-back" onClick={() => onNavigate('settings')}>
            <Icons.arrowLeft />
          </button>
          <h1 className="page-title">Edit Profile</h1>
          <div style={{width: '44px'}} />
        </div>

        <div className="edit-profile-content">
          <div className="profile-field">
            <label className="profile-label">Your Name</label>
            <input
              className="profile-input"
              type="text"
              placeholder="e.g., Theyab"
              value={localProfile.name}
              onChange={(e) => handleChange('name', e.target.value)}
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
          
          <button 
            className="primary-btn" 
            style={{marginTop: '24px'}}
            onClick={handleSave}
          >
            Save Profile
          </button>
        </div>
      </div>
    </div>
  );
}


