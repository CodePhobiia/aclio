// Main App Component - Version 2
import { useState, useCallback, useEffect } from 'react';

// Pages
import {
  WelcomePage,
  OnboardingPage,
  ProfileSetupPage,
  DashboardPage,
  NewGoalPage,
  GoalDetailPage,
  SettingsPage,
  AnalyticsPage,
  ErrorLogPage,
  EditProfilePage,
  ChatPage,
} from './pages';

// Hooks
import { useGoals } from './hooks/useGoals';
import { useTheme } from './hooks/useTheme';
import { usePremium } from './hooks/usePremium';
import { useGamification } from './hooks/useGamification';
import { useProfile } from './hooks/useProfile';

// Utils
import { generateSteps, generateQuestions, expandStep, doItForMe, checkBackendHealth } from './utils/api';
import { clearAllData } from './utils/storage';
import { ErrorTracker } from './utils/errorTracker';

// Constants
import { PREMIUM_CONFIG } from './constants/config';
import { ACHIEVEMENTS } from './constants/gamification';

// Components
import { PaywallModal } from './components/modals/PaywallModal';

export default function App() {
  // Navigation state
  const [view, setView] = useState('loading');
  
  // Hooks
  const profile = useProfile();
  const { theme, toggleTheme } = useTheme();
  const goals = useGoals();
  const premium = usePremium();
  const gamification = useGamification(goals.goals, goals.getProgress);
  
  // Local state
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [goalQuestions, setGoalQuestions] = useState(null);
  const [questionsLoading, setQuestionsLoading] = useState(false);
  const [generationProgress, setGenerationProgress] = useState({ step: 0, message: '' });
  const [expandedSteps, setExpandedSteps] = useState({});
  const [showCelebration, setShowCelebration] = useState(false);

  // Initialize app
  useEffect(() => {
    const init = async () => {
      // Check backend health
      await checkBackendHealth();
      
      // Set initial view based on onboarding status
      if (profile.isOnboarded) {
        setView('dashboard');
      } else {
        setView('welcome');
      }
    };
    init();
  }, [profile.isOnboarded]);

  // Navigation handler
  const navigate = useCallback((newView) => {
    setView(newView);
    setError('');
  }, []);

  // Handle premium feature gating
  const handlePremiumFeature = useCallback((feature, onSuccess) => {
    if (feature === 'goal' && !premium.canCreateGoal(goals.goals.length)) {
      premium.setShowPaywall(true);
      return;
    }
    onSuccess?.();
  }, [premium, goals.goals.length]);

  // Create goal handler
  const handleCreateGoal = useCallback(async (goalData) => {
    setLoading(true);
    setError('');
    setGenerationProgress({ step: 1, message: 'Analyzing your goal...' });

    try {
      setGenerationProgress({ step: 2, message: 'Creating personalized steps...' });
      
      const result = await generateSteps(
        goalData.name,
        profile.profile,
        profile.location,
        goalData.additionalContext
      );

      const newGoal = goals.addGoal({
        name: goalData.name,
        steps: result.steps,
        category: result.category,
        iconKey: goalData.iconKey,
        iconColor: goalData.iconColor,
        dueDate: goalData.dueDate,
      });

      // Award points for first goal
      if (goals.goals.length === 0) {
        gamification.awardGoalPoints(true);
      }

      // Check achievements
      gamification.checkAchievements();

      goals.setActiveGoal(newGoal);
      setGoalQuestions(null);
      navigate('detail');
    } catch (err) {
      setError(err.message || 'Failed to generate goal. Please try again.');
      ErrorTracker.log(err, 'error', { context: 'createGoal' });
    } finally {
      setLoading(false);
      setGenerationProgress({ step: 0, message: '' });
    }
  }, [profile, goals, gamification, navigate]);

  // Generate questions handler
  const handleGenerateQuestions = useCallback(async (goalText) => {
    setQuestionsLoading(true);
    try {
      const result = await generateQuestions(goalText, profile.profile);
      setGoalQuestions({ questions: result.questions, answers: {} });
    } catch (err) {
      console.error('Failed to generate questions:', err);
    } finally {
      setQuestionsLoading(false);
    }
  }, [profile]);

  // Expand step handler
  const handleExpandStep = useCallback(async (step, goal) => {
    try {
      const result = await expandStep(step, goal.name, profile.profile);
      setExpandedSteps(prev => ({
        ...prev,
        [`${goal.id}-${step.id}`]: result
      }));
    } catch (err) {
      ErrorTracker.log(err, 'error', { context: 'expandStep' });
    }
  }, [profile]);

  // Do it for me handler
  const handleDoItForMe = useCallback(async (step, goal) => {
    try {
      const result = await doItForMe(step, goal.name, profile.profile);
      // Mark step as completed and award points
      goals.toggleStep(goal.id, step.id);
      gamification.awardStepPoints();
      return result;
    } catch (err) {
      ErrorTracker.log(err, 'error', { context: 'doItForMe' });
    }
  }, [profile, goals, gamification]);

  // Toggle step with gamification
  const handleToggleStep = useCallback((goalId, stepId) => {
    const wasCompleted = goals.isStepCompleted(goalId, stepId);
    goals.toggleStep(goalId, stepId);
    
    if (!wasCompleted) {
      gamification.awardStepPoints();
      gamification.checkAchievements();
    }
  }, [goals, gamification]);

  // Logout handler
  const handleLogout = useCallback(() => {
    if (confirm('Are you sure you want to sign out? Your data will be preserved.')) {
      profile.resetOnboarding();
      navigate('welcome');
    }
  }, [profile, navigate]);

  // Claim daily bonus
  const handleClaimDailyBonus = useCallback(() => {
    gamification.claimBonus();
  }, [gamification]);

  // Loading state
  if (view === 'loading') {
    return (
      <div className="app app-no-scroll" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div className="loading-spinner">
          <img src="/mascot.png" alt="Loading..." style={{ width: '80px', animation: 'pulse 1s ease infinite' }} />
        </div>
      </div>
    );
  }

  // Render pages based on view
  return (
    <div className="app-root">
      <>
      {view === 'welcome' && (
        <WelcomePage 
          onGetStarted={() => navigate('onboarding')}
          onSignIn={() => {
            profile.completeOnboarding();
            navigate('dashboard');
          }}
        />
      )}

      {view === 'onboarding' && (
        <OnboardingPage 
          onComplete={() => navigate('profile-setup')}
          onSkip={() => navigate('profile-setup')}
        />
      )}

      {view === 'profile-setup' && (
        <ProfileSetupPage
          profile={profile.profile}
          onProfileChange={profile.setProfile}
          onComplete={() => {
            profile.completeOnboarding();
            navigate('dashboard');
          }}
          onSkip={() => {
            profile.completeOnboarding();
            navigate('dashboard');
          }}
        />
      )}

      {view === 'dashboard' && (
        <DashboardPage
          onNavigate={navigate}
          profile={profile.profile}
          getGreeting={profile.getGreeting}
          goals={goals.goals}
          getProgress={goals.getProgress}
          toggleStep={handleToggleStep}
          deleteGoal={goals.deleteGoal}
          setActiveGoal={goals.setActiveGoal}
          searchQuery={searchQuery}
          setSearchQuery={setSearchQuery}
          theme={theme}
          toggleTheme={toggleTheme}
          isPremium={premium.isPremium}
          setShowPaywall={premium.setShowPaywall}
          handlePremiumFeature={handlePremiumFeature}
          userPoints={gamification.points}
          streakData={gamification.streak}
          dailyBonusClaimed={gamification.dailyBonusClaimed}
          claimDailyBonus={handleClaimDailyBonus}
          showPointsPopup={gamification.showPointsPopup}
          showLevelUp={gamification.showLevelUp}
          setShowLevelUp={gamification.setShowLevelUp}
        />
      )}

      {view === 'new' && (
        <NewGoalPage
          onNavigate={navigate}
          onCreateGoal={handleCreateGoal}
          loading={loading}
          error={error}
          profile={profile.profile}
          location={profile.location}
          questionsLoading={questionsLoading}
          goalQuestions={goalQuestions}
          setGoalQuestions={setGoalQuestions}
          onGenerateQuestions={handleGenerateQuestions}
          generationProgress={generationProgress}
        />
      )}

      {view === 'detail' && (
        <GoalDetailPage
          goal={goals.activeGoal}
          onNavigate={navigate}
          toggleStep={handleToggleStep}
          deleteGoal={goals.deleteGoal}
          getProgress={goals.getProgress}
          onExpandStep={handleExpandStep}
          onDoItForMe={handleDoItForMe}
          expandedSteps={expandedSteps}
          isPremium={premium.isPremium}
          canExpandStep={premium.canExpandStep}
          canUseDoItForMe={premium.canUseDoItForMe}
          setShowPaywall={premium.setShowPaywall}
          showCelebration={showCelebration}
          setShowCelebration={setShowCelebration}
        />
      )}

      {view === 'settings' && (
        <SettingsPage
          onNavigate={navigate}
          profile={profile.profile}
          theme={theme}
          toggleTheme={toggleTheme}
          notificationsEnabled={profile.notificationsEnabled}
          setNotificationsEnabled={profile.setNotificationsEnabled}
          location={profile.location}
          locationLoading={profile.locationLoading}
          fetchLocation={profile.fetchLocation}
          clearLocation={profile.clearLocation}
          isPremium={premium.isPremium}
          setShowPaywall={premium.setShowPaywall}
          onLogout={handleLogout}
        />
      )}

      {view === 'analytics' && (
        <AnalyticsPage
          onNavigate={navigate}
          goals={goals.goals}
          getProgress={goals.getProgress}
          userPoints={gamification.points}
          streakData={gamification.streak}
          unlockedAchievements={gamification.unlockedAchievements}
          allAchievements={ACHIEVEMENTS}
        />
      )}

      {view === 'error-log' && (
        <ErrorLogPage onNavigate={navigate} />
      )}

      {view === 'edit-profile' && (
        <EditProfilePage
          profile={profile.profile}
          onSave={profile.setProfile}
          onNavigate={navigate}
        />
      )}

      {view === 'chat' && (
        <ChatPage
          goal={goals.activeGoal}
          profile={profile.profile}
          onNavigate={navigate}
          isPremium={premium.isPremium}
          setShowPaywall={premium.setShowPaywall}
        />
      )}

      {/* Premium Paywall Modal */}
      {premium.showPaywall && (
        <PaywallModal
          onClose={() => premium.setShowPaywall(false)}
          onPurchase={(plan) => {
            // Handle purchase - would integrate with RevenueCat here
            console.log('Purchase plan:', plan);
            premium.setIsPremium(true);
            premium.setShowPaywall(false);
          }}
          isPremium={premium.isPremium}
        />
      )}
      </>
    </div>
  );
}
