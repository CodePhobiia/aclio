// API Utilities
import { API_URL, CATEGORIES } from '../constants/config';

// Check backend health
export const checkBackendHealth = async () => {
  try {
    const response = await fetch(`${API_URL}/health`);
    const data = await response.json();
    const isAvailable = data.status === 'ok' && data.apiKeyConfigured;
    console.log(isAvailable ? '✅ Backend connected' : '⚠️ Backend API key not configured');
    return isAvailable;
  } catch {
    console.log('⚠️ Backend not available - please start the server');
    return false;
  }
};

// Generate steps for a goal
export const generateSteps = async (goal, profile = {}, location = null, additionalContext = null) => {
  const response = await fetch(`${API_URL}/generate-steps`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ 
      goal, 
      profile, 
      location, 
      additionalContext, 
      categories: CATEGORIES.join(', ') 
    })
  });

  if (!response.ok) {
    const err = await response.json();
    if (err.message) {
      throw new Error(err.message);
    }
    throw new Error(err.error || 'Backend server not running. Start it with: cd server && npm start');
  }

  return await response.json();
};

// Generate clarifying questions for a goal
export const generateQuestions = async (goal, profile = {}) => {
  const response = await fetch(`${API_URL}/generate-questions`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ goal, profile })
  });

  if (!response.ok) {
    const err = await response.json();
    throw new Error(err.error || 'Failed to generate questions');
  }

  return await response.json();
};

// Expand a step with more details
export const expandStep = async (step, goal, profile = {}) => {
  const response = await fetch(`${API_URL}/expand-step`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ step, goal, profile })
  });

  if (!response.ok) {
    const err = await response.json();
    throw new Error(err.error || 'Failed to expand step');
  }

  return await response.json();
};

// "Do it for me" - AI completes a step
export const doItForMe = async (step, goal, profile = {}) => {
  const response = await fetch(`${API_URL}/do-it-for-me`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ step, goal, profile })
  });

  if (!response.ok) {
    const err = await response.json();
    throw new Error(err.error || 'Failed to complete step');
  }

  return await response.json();
};

