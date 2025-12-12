// Goals State Management Hook
import { useState, useCallback, useEffect } from 'react';
import { saveGoals, loadGoals } from '../utils/storage';

export function useGoals() {
  const [goals, setGoalsState] = useState(() => loadGoals());
  const [activeGoal, setActiveGoal] = useState(null);

  // Persist goals whenever they change
  useEffect(() => {
    saveGoals(goals);
  }, [goals]);

  // Calculate progress for a goal
  const getProgress = useCallback((goal) => {
    if (!goal?.steps?.length) return 0;
    const completed = goal.completedSteps?.length || 0;
    return Math.round((completed / goal.steps.length) * 100);
  }, []);

  // Add a new goal
  const addGoal = useCallback((goal) => {
    const newGoal = {
      id: Date.now(),
      createdAt: new Date().toISOString(),
      completedSteps: [],
      ...goal
    };
    setGoalsState(prev => [newGoal, ...prev]);
    return newGoal;
  }, []);

  // Update a goal
  const updateGoal = useCallback((goalId, updates) => {
    setGoalsState(prev => prev.map(g => 
      g.id === goalId ? { ...g, ...updates } : g
    ));
  }, []);

  // Delete a goal
  const deleteGoal = useCallback((goalId) => {
    setGoalsState(prev => prev.filter(g => g.id !== goalId));
    if (activeGoal?.id === goalId) {
      setActiveGoal(null);
    }
  }, [activeGoal]);

  // Toggle step completion
  const toggleStep = useCallback((goalId, stepId) => {
    setGoalsState(prev => prev.map(g => {
      if (g.id !== goalId) return g;
      
      const completedSteps = g.completedSteps || [];
      const isCompleted = completedSteps.includes(stepId);
      
      return {
        ...g,
        completedSteps: isCompleted
          ? completedSteps.filter(id => id !== stepId)
          : [...completedSteps, stepId]
      };
    }));

    // Return whether the step is now completed (for points calculation)
    const goal = goals.find(g => g.id === goalId);
    const wasCompleted = goal?.completedSteps?.includes(stepId);
    return !wasCompleted; // Returns true if step is now completed
  }, [goals]);

  // Check if a step is completed
  const isStepCompleted = useCallback((goalId, stepId) => {
    const goal = goals.find(g => g.id === goalId);
    return goal?.completedSteps?.includes(stepId) || false;
  }, [goals]);

  // Get incomplete goals
  const getIncompleteGoals = useCallback(() => {
    return goals.filter(g => getProgress(g) < 100);
  }, [goals, getProgress]);

  // Get completed goals
  const getCompletedGoals = useCallback(() => {
    return goals.filter(g => getProgress(g) === 100);
  }, [goals, getProgress]);

  // Get today's focus (next step from each incomplete goal)
  const getTodaysFocus = useCallback(() => {
    return getIncompleteGoals().map(goal => {
      const nextStep = goal.steps?.find(step => 
        !goal.completedSteps?.includes(step.id)
      );
      return nextStep ? { goal, step: nextStep } : null;
    }).filter(Boolean);
  }, [getIncompleteGoals]);

  // Search goals
  const searchGoals = useCallback((query) => {
    if (!query.trim()) return goals;
    const lowerQuery = query.toLowerCase();
    return goals.filter(g => 
      g.title?.toLowerCase().includes(lowerQuery) ||
      g.steps?.some(s => s.title?.toLowerCase().includes(lowerQuery))
    );
  }, [goals]);

  return {
    goals,
    setGoals: setGoalsState,
    activeGoal,
    setActiveGoal,
    getProgress,
    addGoal,
    updateGoal,
    deleteGoal,
    toggleStep,
    isStepCompleted,
    getIncompleteGoals,
    getCompletedGoals,
    getTodaysFocus,
    searchGoals
  };
}





