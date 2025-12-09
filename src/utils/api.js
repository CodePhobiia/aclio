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

// Generate steps for a goal (non-streaming fallback)
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

// Generate steps with streaming - shows progress as plan is created
export const generateStepsStream = async (goal, profile = {}, location = null, additionalContext = null, onChunk) => {
  const response = await fetch(`${API_URL}/generate-steps-stream`, {
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
    throw new Error(err.message || err.error || 'Failed to generate plan');
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let result = null;

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    const chunk = decoder.decode(value);
    const lines = chunk.split('\n');

    for (const line of lines) {
      if (line.startsWith('data: ')) {
        try {
          const data = JSON.parse(line.slice(6));
          if (data.chunk && onChunk) {
            onChunk(data.chunk);
          }
          if (data.done && data.result) {
            result = data.result;
          }
          if (data.error) {
            throw new Error(data.error);
          }
        } catch (e) {
          // Skip parse errors
        }
      }
    }
  }

  return result;
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

