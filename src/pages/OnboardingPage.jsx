// Onboarding Flow Page
import { useState } from 'react';
import { Icons } from '../constants/icons';
import { ONBOARDING_SLIDES } from '../constants/config';

export function OnboardingPage({ onComplete, onSkip }) {
  const [step, setStep] = useState(0);
  const slide = ONBOARDING_SLIDES[step];
  const SlideIcon = Icons[slide.icon];

  const handleNext = () => {
    if (step < ONBOARDING_SLIDES.length - 1) {
      setStep(step + 1);
    } else {
      onComplete();
    }
  };

  return (
    <div className="app app-no-scroll">
      <div className="onboarding fade-in" key={step}>
        <button className="onboarding-skip-top" onClick={onSkip}>
          Skip
        </button>
        
        <div className="onboarding-content">
          {/* Illustration */}
          <div className="onboarding-illustration">
            <div className="onboarding-blob">
              <div className="onboarding-image-container">
                <img src={slide.image} alt="" className="onboarding-image" />
              </div>
              <div 
                className="onboarding-icon-badge" 
                style={{ background: slide.iconBg, color: slide.iconColor }}
              >
                <SlideIcon />
              </div>
            </div>
          </div>
          
          {/* Title & Subtitle */}
          <h1 className="onboarding-title">{slide.title}</h1>
          <p className="onboarding-text">{slide.text}</p>
          
          {/* Screen 1: Feature List */}
          {slide.features && (
            <div className="onboarding-features">
              {slide.features.map((feature, i) => {
                const FeatureIcon = Icons[feature.icon];
                return (
                  <div key={i} className="onboarding-feature-item">
                    <span className="onboarding-feature-icon"><FeatureIcon /></span>
                    <span>{feature.text}</span>
                  </div>
                );
              })}
            </div>
          )}
          
          {/* Screen 2: Task Cards */}
          {slide.tasks && (
            <div className="onboarding-task-list">
              {slide.tasks.slice(0, 4).map((task, i) => (
                <div key={task} className={`onboarding-task-card ${i < 2 ? 'completed' : ''}`}>
                  <div className="onboarding-task-icon">
                    {i < 2 ? <Icons.check /> : <div className="onboarding-task-bullet" />}
                  </div>
                  <span className={i < 2 ? 'task-done' : ''}>{task}</span>
                </div>
              ))}
            </div>
          )}
          
          {/* Screen 3: Achievement Badge */}
          {slide.badge && (
            <div className="onboarding-badge">
              <span className="onboarding-badge-icon"><Icons.trophy /></span>
              <span>{slide.badge.text}</span>
            </div>
          )}
        </div>
        
        {/* Bottom Section */}
        <div className="onboarding-footer">
          <div className="onboarding-dots">
            {ONBOARDING_SLIDES.map((_, i) => (
              <div key={i} className={`onboarding-dot ${i === step ? 'active' : ''}`} />
            ))}
          </div>
          <button className="onboarding-cta" onClick={handleNext}>
            {step < ONBOARDING_SLIDES.length - 1 ? 'Next' : 'Get Started'}
          </button>
        </div>
      </div>
    </div>
  );
}




