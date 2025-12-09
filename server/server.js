/**
 * Achieve AI - Backend Server
 * Using OpenAI GPT for goal planning
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const crypto = require('crypto');

const app = express();
const PORT = process.env.PORT || 3001;

// ═══════════════════════════════════════════════════════════════════════════════
// REQUEST LOGGING & OBSERVABILITY
// ═══════════════════════════════════════════════════════════════════════════════

// Generate unique operation ID
const generateOpId = () => crypto.randomBytes(4).toString('hex');

// Format duration for logging
const formatDuration = (ms) => {
  if (ms < 1000) return `${ms}ms`;
  return `${(ms / 1000).toFixed(2)}s`;
};

// Request logger middleware
const requestLogger = (req, res, next) => {
  const opId = generateOpId();
  const startTime = Date.now();
  
  // Attach to request for use in handlers
  req.opId = opId;
  req.startTime = startTime;
  
  // Log request start
  const logData = {
    opId,
    method: req.method,
    path: req.path,
    timestamp: new Date().toISOString(),
  };
  
  // Add relevant body info (without sensitive data)
  if (req.body) {
    if (req.body.goal) logData.goal = req.body.goal.substring(0, 50);
    if (req.body.message) logData.message = req.body.message.substring(0, 50);
    if (req.body.goalName) logData.goalName = req.body.goalName;
  }
  
  console.log(`\n🚀 [${opId}] START ${req.method} ${req.path}`, JSON.stringify(logData));
  
  // Capture response
  const originalSend = res.send;
  res.send = function(body) {
    const duration = Date.now() - startTime;
    const status = res.statusCode;
    
    // Color code based on duration
    let durationIcon = '⚡';
    if (duration > 2000) durationIcon = '🐢';
    else if (duration > 5000) durationIcon = '🔴';
    else if (duration > 10000) durationIcon = '💀';
    
    const statusIcon = status >= 400 ? '❌' : '✅';
    
    console.log(`${statusIcon} [${opId}] END ${req.method} ${req.path} | Status: ${status} | ${durationIcon} Duration: ${formatDuration(duration)}`);
    
    // Warn on slow requests
    if (duration > 5000) {
      console.warn(`⚠️  [${opId}] SLOW REQUEST: ${req.path} took ${formatDuration(duration)}`);
    }
    
    return originalSend.call(this, body);
  };
  
  next();
};

// Middleware - allow all origins for development
app.use(cors({
  origin: true, // Allow all origins (for iOS Capacitor app)
  methods: ['GET', 'POST'],
  credentials: true
}));
app.use(express.json());
app.use(requestLogger);

// API Keys from environment variables
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

// Model configuration - GPT 5.1
const MODELS = {
  MAIN: 'gpt-5.1',          // GPT 5.1 for all tasks
  FAST: 'gpt-4o-mini'       // Fastest for simple tasks
};

const PRIMARY_MODEL = 'gpt-5.1';

// ═══════════════════════════════════════════════════════════════════════════════
// ACLIO PERSONA - Advanced Goal-Building AI Coach
// ═══════════════════════════════════════════════════════════════════════════════

const ACLIO_CORE = `You are Aclio, an advanced goal-building AI coach.

Your job is to transform any user goal — vague or specific — into a clear, actionable, realistic, and personalized plan using expert-level reasoning.

Your behavior combines:
- Strategic intelligence
- Coaching awareness
- Practical execution planning
- Empathy and clarity
- No fluff, no filler, no clichés

Core Rules:
- Be extremely actionable. Replace vague ideas with specific tasks — what to do, how to do it, how long it takes, how often, and why it matters.
- Prioritize usefulness > quantity. Never add steps that don't materially advance the goal.
- Avoid being generic. Every plan is tailored to the user's life, constraints, and resources.
- Keep the user moving. Every response should contain at least one immediate action they can take.
- Avoid unrealistic, extreme, or dangerous suggestions.
- Be clear, structured, and logical.

Tone: Confident, clear, calm, intelligent, supportive but not cheesy, direct but not harsh. Nothing robotic. Nothing motivational-poster. Just a highly competent goal-building expert.`;

const SYSTEM_PROMPTS = {
  // For generating goal plans
  PLAN: `${ACLIO_CORE}

OUTPUT FORMAT: Return ONLY a JSON object with this structure:
{
  "category": "<category>",
  "steps": [
    {"id": 1, "title": "<action verb + specific task>", "description": "<what to do, how, why it matters>", "duration": "<realistic time>"}
  ]
}

Create 8-12 high-impact steps. Each step must be:
- Specific and actionable (not vague)
- Include real tools, apps, or resources by name
- Have clear success criteria
- Be achievable in the stated timeframe

No explanation outside the JSON.`,

  // For expanding steps
  EXPAND: `${ACLIO_CORE}

The user wants EXPANSION on a specific step. Provide:
- Deeper reasoning and context
- Step-by-step sequencing
- Specific examples
- Real tools, resources, URLs
- Common pitfalls to avoid
- How to know when it's done well

OUTPUT FORMAT: JSON with detailedGuide, resources, tips, searchQuery.`,

  // For "do it for me" tasks
  TASK: `${ACLIO_CORE}

The user wants you to DO IT FOR THEM. Take full control and produce the entire output:
- If it's a schedule, give real times and specific activities
- If it's a plan, give complete actionable steps
- If it's content, write the full thing ready to use
- No placeholders, no [fill this in], no templates

Deliver a complete, ready-to-use result.`,

  // For chat
  CHAT: `${ACLIO_CORE}

Adapt your response to what the user needs:
- If they want "help," explain lightly
- If they want "expand," provide more depth
- If they want "simplify," make it lighter
- If they want motivation, provide calm, non-cheesy encouragement

Keep responses focused (2-3 paragraphs). Always include at least one immediate action.`,

  // For questions
  QUESTIONS: `You are Aclio. The user's goal needs clarification.

Ask ONE precise clarifying question to understand:
- Their true objective (what they really want)
- Their constraints (time, resources, skill level)
- Their timeline

OUTPUT: JSON array with exactly 3 questions:
[{"id":1,"question":"<short question>","placeholder":"<example answer>"}]

Never overwhelm. Never ask multiple vague questions. Be precise.`
};

if (!OPENAI_API_KEY) {
  console.error('❌ OPENAI_API_KEY is not set in environment variables!');
  console.log('Please create a .env file with: OPENAI_API_KEY=your_api_key_here');
}

// Helper function to call OpenAI API
async function callOpenAI(systemPrompt, userMessage, options = {}, opId = 'N/A') {
  const { model = PRIMARY_MODEL, maxTokens = 4096, temperature = 0.7 } = options;
  
  console.log(`   📡 [${opId}] Calling OpenAI API (${model})...`);
  const apiStart = Date.now();
  
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${OPENAI_API_KEY}`
    },
    body: JSON.stringify({
      model,
      max_completion_tokens: maxTokens,
      temperature,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userMessage }
      ]
    })
  });

  const apiDuration = Date.now() - apiStart;
  
  if (!response.ok) {
    const err = await response.json();
    console.log(`   ❌ [${opId}] OpenAI API ERROR after ${formatDuration(apiDuration)}: ${err.error?.message}`);
    throw new Error(err.error?.message || 'OpenAI API Error');
  }

  const data = await response.json();
  const tokenUsage = data.usage ? `(${data.usage.prompt_tokens}→${data.usage.completion_tokens} tokens)` : '';
  console.log(`   ✅ [${opId}] OpenAI API responded in ${formatDuration(apiDuration)} ${tokenUsage}`);
  
  return data.choices[0].message.content;
}

// Helper function for multi-turn conversations
async function callOpenAIChat(systemPrompt, messages, options = {}, opId = 'N/A') {
  const { model = PRIMARY_MODEL, maxTokens = 4096, temperature = 0.8 } = options;
  
  console.log(`   📡 [${opId}] Calling OpenAI Chat API (${model})...`);
  const apiStart = Date.now();
  
  // Convert messages to OpenAI format and add system prompt
  const openAIMessages = [
    { role: 'system', content: systemPrompt },
    ...messages.map(m => ({ role: m.role, content: m.content }))
  ];
  
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${OPENAI_API_KEY}`
    },
    body: JSON.stringify({
      model,
      max_completion_tokens: maxTokens,
      temperature,
      messages: openAIMessages
    })
  });

  const apiDuration = Date.now() - apiStart;
  
  if (!response.ok) {
    const err = await response.json();
    console.log(`   ❌ [${opId}] OpenAI Chat API ERROR after ${formatDuration(apiDuration)}: ${err.error?.message}`);
    throw new Error(err.error?.message || 'OpenAI API Error');
  }

  const data = await response.json();
  const tokenUsage = data.usage ? `(${data.usage.prompt_tokens}→${data.usage.completion_tokens} tokens)` : '';
  console.log(`   ✅ [${opId}] OpenAI Chat API responded in ${formatDuration(apiDuration)} ${tokenUsage}`);
  
  return data.choices[0].message.content;
}

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    apiKeyConfigured: !!OPENAI_API_KEY,
    models: MODELS
  });
});

// Content moderation - ONLY block genuinely dangerous content
const isInappropriateGoal = (goal) => {
  const lowerGoal = goal.toLowerCase();
  
  // Only block: weapons, violence, crimes, self-harm, suicide
  const dangerousPatterns = [
    // Weapons & Violence
    /\b(build|make|create|construct)\b.*(bomb|explosive|weapon|gun|firearm)/i,
    /\bhow to (kill|murder|assassinate)/i,
    /\b(kill|murder|assassinate)\s+(someone|a person|my|the)/i,
    
    // Self-harm & Suicide
    /\b(kill|hurt|harm)\s*(myself|yourself)/i,
    /\bsuicide\b/i,
    /\bself[- ]?harm/i,
    /\bend my life\b/i,
    /\bways to die\b/i,
    
    // Serious crimes
    /\b(how to|planning to)\s*(rob|kidnap|abduct|traffick)/i,
    /\bchild\s*(porn|abuse|exploit)/i,
    /\bterrorist|terrorism\b/i,
    /\bdrug\s*(deal|traffick|sell|manufacture)/i,
    /\bpoison\s*(someone|a person|my|the)/i,
  ];
  
  return dangerousPatterns.some(pattern => pattern.test(lowerGoal));
};

// Generate steps for a goal (Uses Sonnet 4.5)
app.post('/api/generate-steps', async (req, res) => {
  try {
    const { goal, profile, location, additionalContext, categories } = req.body;
    
    if (!goal) {
      return res.status(400).json({ error: 'Goal is required' });
    }
    
    // Check for dangerous content only
    if (isInappropriateGoal(goal)) {
      return res.status(400).json({ 
        error: 'inappropriate',
        message: "I can't help with goals that could cause harm. If you're struggling, please reach out to a crisis helpline. Otherwise, try rephrasing your goal!"
      });
    }
    
    if (!OPENAI_API_KEY) {
      return res.status(500).json({ error: 'API key not configured on server' });
    }

    const userContext = profile?.name 
      ? `The user is ${profile.name}, ${profile.age ? profile.age + ' years old' : ''} ${profile.gender ? '(' + profile.gender + ')' : ''}. Tailor the plan to be appropriate and relevant for them.`
      : '';
    
    const contextFromQuestions = additionalContext 
      ? `\nAdditional context from user:\n${additionalContext}`
      : '';
    
    const locationContext = location 
      ? `The user is located in ${location.display}${location.country ? ', ' + location.country : ''}. When suggesting resources like classes, studios, gyms, stores, or any local businesses, include a "mapSearch" field with the Google Maps search query.`
      : '';

    const categoriesList = categories || 'Health & Fitness, Career, Education, Finance, Creative, Personal Growth, Relationships, Travel, Home & Living, Technology';

    // LEAN prompt - no reasoning triggers
    const systemPrompt = SYSTEM_PROMPTS.PLAN;

    const userMessage = `Goal: "${goal}"
${userContext}${contextFromQuestions}${locationContext}

Return JSON: {"category":"<one of: ${categoriesList}>","steps":[{"id":1,"title":"<action>","description":"<how + why>","duration":"<time>"${location ? ',"mapSearch":"<maps query>"' : ''}},...]}

8-12 steps. Be specific. Real tools/apps. No obvious steps.`;

    const content = await callOpenAI(systemPrompt, userMessage, {
      model: PRIMARY_MODEL,
      maxTokens: 4000,  // Reduced from 8000
      temperature: 0.7
    }, req.opId);
    
    let cleanContent = content.trim();
    if (cleanContent.startsWith('```')) {
      cleanContent = cleanContent.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    }
    
    // Check if AI refused (non-JSON response)
    if (!cleanContent.startsWith('{') && !cleanContent.startsWith('[')) {
      console.log('AI refused request:', cleanContent.substring(0, 200));
      return res.status(400).json({ 
        error: 'ai_refused',
        message: "I couldn't generate a plan for that. Try rephrasing your goal or being more specific about what you want to achieve!"
      });
    }
    
    try {
      const result = JSON.parse(cleanContent);
      res.json(result);
    } catch (parseError) {
      console.error('JSON parse error:', parseError, 'Content:', cleanContent.substring(0, 500));
      return res.status(400).json({ 
        error: 'parse_error',
        message: "Something went wrong creating your plan. Please try rephrasing your goal."
      });
    }
    
  } catch (error) {
    console.error('Generate steps error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Generate steps - STREAMING version for instant feedback
app.post('/api/generate-steps-stream', async (req, res) => {
  const opId = req.opId || generateOpId();
  
  try {
    const { goal, profile, location, additionalContext, categories } = req.body;
    
    if (!goal) {
      return res.status(400).json({ error: 'Goal is required' });
    }
    
    if (isInappropriateGoal(goal)) {
      return res.status(400).json({ 
        error: 'inappropriate',
        message: "I can't help with goals that could cause harm."
      });
    }
    
    if (!OPENAI_API_KEY) {
      return res.status(500).json({ error: 'API key not configured on server' });
    }

    // Set up SSE
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.setHeader('Access-Control-Allow-Origin', '*');

    const userContext = profile?.name 
      ? `User: ${profile.name}${profile.age ? ', ' + profile.age : ''}.`
      : '';
    
    const contextFromQuestions = additionalContext ? `Context: ${additionalContext}` : '';
    const locationContext = location ? `Location: ${location.display}.` : '';
    const categoriesList = categories || 'Health & Fitness, Career, Education, Finance, Creative, Personal Growth, Relationships, Travel, Home & Living, Technology';

    const systemPrompt = SYSTEM_PROMPTS.PLAN;
    const userMessage = `Goal: "${goal}"
${userContext}${contextFromQuestions}${locationContext}

Return JSON: {"category":"<${categoriesList}>","steps":[{"id":1,"title":"<action>","description":"<how>","duration":"<time>"},...]}
8-12 steps. Specific tools/apps. No obvious steps.`;

    console.log(`   📡 [${opId}] Starting streaming plan generation...`);
    const streamStart = Date.now();

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${OPENAI_API_KEY}`
      },
      body: JSON.stringify({
        model: PRIMARY_MODEL,
        max_completion_tokens: 4000,
        temperature: 0.7,
        stream: true,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userMessage }
        ]
      })
    });

    if (!response.ok) {
      const err = await response.json();
      throw new Error(err.error?.message || 'API Error');
    }

    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let fullContent = '';
    let firstChunk = true;

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      const chunk = decoder.decode(value);
      const lines = chunk.split('\n');

      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const data = line.slice(6);
          if (data === '[DONE]') continue;
          
          try {
            const parsed = JSON.parse(data);
            // OpenAI format: choices[0].delta.content
            const content = parsed.choices?.[0]?.delta?.content;
            if (content) {
              if (firstChunk) {
                console.log(`   ⚡ [${opId}] First chunk in ${formatDuration(Date.now() - streamStart)}`);
                firstChunk = false;
              }
              fullContent += content;
              res.write(`data: ${JSON.stringify({ chunk: content })}\n\n`);
            }
          } catch (e) {}
        }
      }
    }

    // Parse and send final result
    let cleanContent = fullContent.trim();
    if (cleanContent.startsWith('```')) {
      cleanContent = cleanContent.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    }

    try {
      const result = JSON.parse(cleanContent);
      res.write(`data: ${JSON.stringify({ done: true, result })}\n\n`);
      console.log(`   ✅ [${opId}] Stream complete in ${formatDuration(Date.now() - streamStart)}`);
    } catch (e) {
      res.write(`data: ${JSON.stringify({ done: true, raw: cleanContent })}\n\n`);
    }
    
    res.end();
    
  } catch (error) {
    console.error(`   ❌ [${opId}] Stream error:`, error);
    res.write(`data: ${JSON.stringify({ error: error.message })}\n\n`);
    res.end();
  }
});

// Generate context questions for a goal (Uses Haiku for speed)
app.post('/api/generate-questions', async (req, res) => {
  try {
    const { goal } = req.body;
    
    if (!goal) {
      return res.status(400).json({ error: 'Goal is required' });
    }
    
    // Check for dangerous content only
    if (isInappropriateGoal(goal)) {
      return res.status(400).json({ 
        error: 'inappropriate',
        message: "I can't help with goals that could cause harm."
      });
    }
    
    if (!OPENAI_API_KEY) {
      return res.status(500).json({ error: 'API key not configured on server' });
    }

    // LEAN prompt for questions
    const systemPrompt = SYSTEM_PROMPTS.QUESTIONS;

    const userMessage = `Goal: "${goal}"
Return JSON array: [{"id":1,"question":"<short question>","placeholder":"<example answer>"},...]
3 questions about: experience level, timeline, constraints.`;

    const content = await callOpenAI(systemPrompt, userMessage, {
      model: MODELS.FAST,  // Use Haiku for simple question generation
      maxTokens: 500,
      temperature: 0.7
    }, req.opId);
    
    let cleanContent = content.trim();
    if (cleanContent.startsWith('```')) {
      cleanContent = cleanContent.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    }
    
    // Check if AI refused (non-JSON response)
    if (!cleanContent.startsWith('[') && !cleanContent.startsWith('{')) {
      return res.status(400).json({ 
        error: 'ai_refused',
        message: "Couldn't process that goal. Try rephrasing it!"
      });
    }
    
    try {
      const questions = JSON.parse(cleanContent);
      res.json({ questions });
    } catch (parseError) {
      console.error('JSON parse error:', parseError);
      return res.status(400).json({ 
        error: 'parse_error',
        message: "Something went wrong. Please try rephrasing your goal."
      });
    }
    
  } catch (error) {
    console.error('Generate questions error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Expand step with resources (Uses Sonnet 4.5)
app.post('/api/expand-step', async (req, res) => {
  try {
    const { goalName, step } = req.body;
    
    if (!step) {
      return res.status(400).json({ error: 'Step is required' });
    }
    
    if (!OPENAI_API_KEY) {
      return res.status(500).json({ error: 'API key not configured on server' });
    }

    // LEAN prompt for expand
    const systemPrompt = SYSTEM_PROMPTS.EXPAND;

    const userMessage = `Goal: "${goalName}"
Step: "${step.title}" - ${step.description}

Return JSON: {"detailedGuide":"<2-3 paragraphs>","resources":[{"name":"...","type":"app|video|article","url":"...","cost":"Free/$X"}],"tips":["tip1","tip2"],"searchQuery":"<google search>"}

Real URLs only. Be specific.`;

    const content = await callOpenAI(systemPrompt, userMessage, {
      model: PRIMARY_MODEL,
      maxTokens: 2000,
      temperature: 0.7
    }, req.opId);
    
    let cleanContent = content.trim();
    if (cleanContent.startsWith('```')) {
      cleanContent = cleanContent.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    }
    
    const result = JSON.parse(cleanContent);
    res.json(result);
    
  } catch (error) {
    console.error('Expand step error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Do it for me - AI completes the task (Uses Opus 4.5 - heavy task)
app.post('/api/do-it-for-me', async (req, res) => {
  try {
    const { goalName, step, profile } = req.body;
    
    if (!step) {
      return res.status(400).json({ error: 'Step is required' });
    }
    
    if (!OPENAI_API_KEY) {
      return res.status(500).json({ error: 'API key not configured on server' });
    }

    // LEAN prompt for do-it-for-me
    const systemPrompt = SYSTEM_PROMPTS.TASK;

    const userMessage = `Goal: "${goalName}"
Task: "${step.title}" - ${step.description}

Complete this task NOW. Give the finished product, not instructions. Use markdown formatting.`;

    const result = await callOpenAI(systemPrompt, userMessage, {
      model: PRIMARY_MODEL,
      maxTokens: 3000,
      temperature: 0.7
    }, req.opId);
    
    res.json({ result });
    
  } catch (error) {
    console.error('Do it for me error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Talk to Aclio - chat about a goal (Premium feature) (Uses Opus 4.5 - heavy task)
app.post('/api/talk-to-aclio', async (req, res) => {
  try {
    const { goalName, goalCategory, steps, completedSteps, message, chatHistory, profile } = req.body;
    
    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }
    
    if (!OPENAI_API_KEY) {
      return res.status(500).json({ error: 'API key not configured on server' });
    }

    const userContext = profile?.name 
      ? `The user is ${profile.name}${profile.age ? ', ' + profile.age + ' years old' : ''}.`
      : '';
    
    const completedCount = completedSteps?.length || 0;
    const totalSteps = steps?.length || 0;
    const progress = totalSteps > 0 ? Math.round((completedCount / totalSteps) * 100) : 0;
    
    const stepsSummary = steps?.slice(0, 10).map((s, i) => 
      `${i + 1}. ${s.title}${completedSteps?.includes(s.id) ? ' ✓' : ''}`
    ).join('\n') || 'No steps yet';

    // LEAN prompt for chat
    const systemPrompt = `${SYSTEM_PROMPTS.CHAT}
${userContext}
Goal: "${goalName}" (${goalCategory || 'Personal'}) - ${progress}% done
Steps: ${stepsSummary}`;

    // Build messages array with chat history (without system message for Anthropic)
    const messages = [];
    
    // Add chat history
    if (chatHistory && chatHistory.length > 0) {
      chatHistory.forEach(msg => {
        messages.push({
          role: msg.role === 'assistant' ? 'assistant' : 'user',
          content: msg.content
        });
      });
    }
    
    // Add current message
    messages.push({ role: 'user', content: message });

    const aiResponse = await callOpenAIChat(systemPrompt, messages, {
      model: PRIMARY_MODEL,
      maxTokens: 1000,
      temperature: 0.8
    }, req.opId);
    
    res.json({ response: aiResponse });
    
  } catch (error) {
    console.error('Talk to Aclio error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Talk to Aclio - STREAMING version for instant response feel
app.post('/api/talk-to-aclio-stream', async (req, res) => {
  const opId = req.opId || generateOpId();
  
  try {
    const { goalName, goalCategory, steps, completedSteps, message, chatHistory, profile } = req.body;
    
    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }
    
    if (!OPENAI_API_KEY) {
      return res.status(500).json({ error: 'API key not configured on server' });
    }

    // Set up SSE headers
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.setHeader('Access-Control-Allow-Origin', '*');

    const userContext = profile?.name 
      ? `The user is ${profile.name}${profile.age ? ', ' + profile.age + ' years old' : ''}.`
      : '';
    
    const completedCount = completedSteps?.length || 0;
    const totalSteps = steps?.length || 0;
    const progress = totalSteps > 0 ? Math.round((completedCount / totalSteps) * 100) : 0;
    
    const stepsSummary = steps?.slice(0, 10).map((s, i) => 
      `${i + 1}. ${s.title}${completedSteps?.includes(s.id) ? ' ✓' : ''}`
    ).join('\n') || 'No steps yet';

    // Shorter system prompt for faster streaming
    const systemPrompt = `You are Aclio, a warm and action-focused personal goal coach. Be encouraging but direct.

USER CONTEXT: ${userContext}
GOAL: "${goalName}" (${goalCategory || 'Personal'})
Progress: ${progress}% (${completedCount}/${totalSteps} steps)

Current plan:
${stepsSummary}

Keep responses focused (2-3 paragraphs). Be conversational and valuable. Don't be generic - give specific advice.`;

    // Build messages
    const messages = [];
    if (chatHistory && chatHistory.length > 0) {
      chatHistory.slice(-4).forEach(msg => {  // Only last 4 messages for speed
        messages.push({
          role: msg.role === 'assistant' ? 'assistant' : 'user',
          content: msg.content
        });
      });
    }
    messages.push({ role: 'user', content: message });

    console.log(`   📡 [${opId}] Starting streaming response (GPT)...`);
    const streamStart = Date.now();

    // Convert messages to OpenAI format
    const openAIMessages = [
      { role: 'system', content: systemPrompt },
      ...messages.map(m => ({ role: m.role, content: m.content }))
    ];

    // Call OpenAI with streaming
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${OPENAI_API_KEY}`
      },
      body: JSON.stringify({
        model: PRIMARY_MODEL,
        max_completion_tokens: 800,
        temperature: 0.7,
        stream: true,
        messages: openAIMessages
      })
    });

    if (!response.ok) {
      const err = await response.json();
      throw new Error(err.error?.message || 'OpenAI API Error');
    }

    // Stream the response
    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let fullResponse = '';
    let firstChunkTime = null;

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      const chunk = decoder.decode(value);
      const lines = chunk.split('\n');

      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const data = line.slice(6);
          if (data === '[DONE]') continue;
          
          try {
            const parsed = JSON.parse(data);
            // OpenAI format: choices[0].delta.content
            const content = parsed.choices?.[0]?.delta?.content;
            if (content) {
              if (!firstChunkTime) {
                firstChunkTime = Date.now();
                console.log(`   ⚡ [${opId}] First chunk in ${formatDuration(firstChunkTime - streamStart)}`);
              }
              fullResponse += content;
              // Send chunk to client
              res.write(`data: ${JSON.stringify({ text: content })}\n\n`);
            }
          } catch (e) {
            // Skip non-JSON lines
          }
        }
      }
    }

    const streamDuration = Date.now() - streamStart;
    console.log(`   ✅ [${opId}] Stream complete in ${formatDuration(streamDuration)} (${fullResponse.length} chars)`);

    // Send done signal
    res.write(`data: ${JSON.stringify({ done: true })}\n\n`);
    res.end();
    
  } catch (error) {
    console.error(`   ❌ [${opId}] Stream error:`, error);
    res.write(`data: ${JSON.stringify({ error: error.message })}\n\n`);
    res.end();
  }
});

// Start server - listen on all interfaces for network access
app.listen(PORT, '0.0.0.0', () => {
  console.log(`
  ╔═══════════════════════════════════════════════════════════╗
  ║                                                           ║
  ║   🎯 Achieve AI Server                                    ║
  ║                                                           ║
  ║   Server running on http://0.0.0.0:${PORT}                  ║
  ║   OpenAI API: ${OPENAI_API_KEY ? '✅ Configured' : '❌ Missing'}                              ║
  ║                                                           ║
  ║   Models:                                                 ║
  ║   • GPT-5.1 → all tasks (fast + high quality)             ║
  ║   • GPT-4o-mini → questions (fastest)                     ║
  ║                                                           ║
  ╚═══════════════════════════════════════════════════════════╝
  `);
});

