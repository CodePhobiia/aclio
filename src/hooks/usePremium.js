// Premium Subscription Hook
import { useState, useCallback } from 'react';
import { 
  loadPremium, 
  savePremium,
  getDailyUses,
  incrementDailyUses 
} from '../utils/storage';
import { PREMIUM_CONFIG } from '../constants/config';

export function usePremium() {
  const [isPremium, setIsPremiumState] = useState(() => loadPremium());
  const [showPaywall, setShowPaywall] = useState(false);

  // Set premium status
  const setIsPremium = useCallback((value) => {
    setIsPremiumState(value);
    savePremium(value);
  }, []);

  // Check if user can create more goals
  const canCreateGoal = useCallback((currentGoalCount) => {
    if (isPremium) return true;
    return currentGoalCount < PREMIUM_CONFIG.FREE_GOAL_LIMIT;
  }, [isPremium]);

  // Check if user can use "Do it for me" feature
  const canUseDoItForMe = useCallback(() => {
    if (isPremium) return true;
    const uses = getDailyUses('achieve_doitforme_uses');
    return uses < PREMIUM_CONFIG.FREE_DOITFORME_DAILY;
  }, [isPremium]);

  // Check if user can expand steps
  const canExpandStep = useCallback(() => {
    if (isPremium) return true;
    const uses = getDailyUses('achieve_expand_uses');
    return uses < PREMIUM_CONFIG.FREE_EXPAND_DAILY;
  }, [isPremium]);

  // Use a premium feature (returns true if allowed)
  const usePremiumFeature = useCallback((feature, onSuccess) => {
    let canUse = false;
    
    switch (feature) {
      case 'doitforme':
        canUse = canUseDoItForMe();
        if (canUse && !isPremium) {
          incrementDailyUses('achieve_doitforme_uses');
        }
        break;
      case 'expand':
        canUse = canExpandStep();
        if (canUse && !isPremium) {
          incrementDailyUses('achieve_expand_uses');
        }
        break;
      default:
        canUse = isPremium;
    }

    if (canUse) {
      onSuccess?.();
      return true;
    } else {
      setShowPaywall(true);
      return false;
    }
  }, [isPremium, canUseDoItForMe, canExpandStep]);

  // Get remaining free uses
  const getRemainingUses = useCallback((feature) => {
    if (isPremium) return Infinity;
    
    switch (feature) {
      case 'doitforme':
        return PREMIUM_CONFIG.FREE_DOITFORME_DAILY - getDailyUses('achieve_doitforme_uses');
      case 'expand':
        return PREMIUM_CONFIG.FREE_EXPAND_DAILY - getDailyUses('achieve_expand_uses');
      default:
        return 0;
    }
  }, [isPremium]);

  return {
    isPremium,
    setIsPremium,
    showPaywall,
    setShowPaywall,
    canCreateGoal,
    canUseDoItForMe,
    canExpandStep,
    usePremiumFeature,
    getRemainingUses,
    config: PREMIUM_CONFIG
  };
}





