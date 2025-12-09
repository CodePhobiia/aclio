// Premium Paywall Modal - Gemini Design
import { useState } from 'react';
import { Icons } from '../../constants/icons';
import { PREMIUM_CONFIG } from '../../constants/config';

export function PaywallModal({ onClose, onPurchase, isPremium }) {
  const [selectedPlan, setSelectedPlan] = useState('yearly');
  const [trialEnabled, setTrialEnabled] = useState(true);

  if (isPremium) return null;

  // Plan pricing
  const plans = {
    weekly: { period: 'Weekly', price: '$2.99', priceValue: '2.99' },
    monthly: { period: 'Monthly', price: '$7.99', priceValue: '7.99' },
    yearly: { period: 'Yearly', price: '$49.99', priceValue: '49.99', isBestValue: true },
  };

  // Premium features with titles and descriptions
  const premiumFeatures = [
    { 
      title: 'Unlimited Goals', 
      desc: 'Create as many goals as you want without restrictions.' 
    },
    { 
      title: 'Unlimited Do It For Me & Expands', 
      desc: 'AI can generate steps, expansions, and tasks for any goal, anytime.' 
    },
    { 
      title: 'Achievement Sharing', 
      desc: 'Share your milestones, streaks, and completed goals with friends.' 
    },
    { 
      title: 'Priority AI Responses', 
      desc: 'Get faster and more accurate AI assistance with priority processing.' 
    },
  ];

  const selectedPlanData = plans[selectedPlan];

  return (
    <div className="paywall-modal" onClick={onClose}>
      <div className="paywall-content" onClick={e => e.stopPropagation()}>
        <button className="paywall-close" onClick={onClose}>
          <Icons.x />
        </button>
        
        {/* Mascot */}
        <img 
          src="/Mascot face Icon.png" 
          alt="Aclio mascot" 
          className="paywall-header-mascot"
        />
        
        <h2 className="paywall-title">Unlock Aclio Premium</h2>
        
        {/* Features with checkmarks and descriptions */}
        <div className="paywall-features">
          {premiumFeatures.map((feature, i) => (
            <div key={i} className="paywall-feature">
              <div className="paywall-feature-icon">
                <Icons.check />
              </div>
              <div className="paywall-feature-text">
                <h4>{feature.title}</h4>
                <p>{feature.desc}</p>
              </div>
            </div>
          ))}
        </div>
        
        {/* Gradient Plan Card */}
        <div className="paywall-plan-card">
          <p className="paywall-plan-label">{selectedPlanData.period} Plan</p>
          <p className="paywall-plan-price-large">
            {selectedPlanData.price}<span> / {selectedPlan === 'yearly' ? 'year' : selectedPlan === 'monthly' ? 'month' : 'week'}</span>
          </p>
        </div>
        
        {/* Plan Selection */}
        <div className="paywall-plan-buttons">
          {Object.entries(plans).map(([key, plan]) => (
            <button
              key={key}
              className={`paywall-plan-btn ${selectedPlan === key ? 'selected' : ''}`}
              onClick={() => setSelectedPlan(key)}
            >
              {plan.period}
              {plan.isBestValue && <span className="paywall-best-badge">Best</span>}
            </button>
          ))}
        </div>
        
        {/* Trial Toggle */}
        <div className="paywall-trial-toggle">
          <span className="paywall-trial-label">3-day free trial</span>
          <button 
            className={`paywall-toggle ${trialEnabled ? 'active' : ''}`}
            onClick={() => setTrialEnabled(!trialEnabled)}
          />
        </div>
        
        {/* CTA */}
        <button 
          className="paywall-cta"
          onClick={() => onPurchase(selectedPlan)}
        >
          Continue
        </button>
        
        <p className="paywall-terms">
          No commitments. Cancel anytime.
        </p>
      </div>
    </div>
  );
}

