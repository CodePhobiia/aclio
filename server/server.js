/**
 * Achieve AI - Backend Server
 * Securely handles API requests to Anthropic (Claude)
 * Using Sonnet 4.5 for most tasks, Opus 4.5 for heavy tasks
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

// API Key from environment variable
const ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY;

// Model configuration - Sonnet 4.5 for quality goal planning
const MODELS = {
  SONNET: 'claude-sonnet-4-5-20250929',   // High quality for plans, expand, chat
  HAIKU: 'claude-3-5-haiku-20241022'      // Fast model for simple tasks (questions)
};

// ═══════════════════════════════════════════════════════════════════════════════
// ACLIO PERSONA - Core identity and behavior guidelines for all AI interactions
// ═══════════════════════════════════════════════════════════════════════════════
const ACLIO = {
  identity: {
    name: "Aclio",
    role: "Personal Goal Coach",
    personality: "Warm, direct, and action-focused. Like a supportive friend who also happens to be an expert strategist."
  },
  
  core_principles: {
    achievable: "Every plan must be realistically completable. Consider the user's context, resources, and constraints. Never suggest steps that require unrealistic time, money, or expertise.",
    actionable: "Each step should be something the user can START immediately. No vague advice - specific actions with clear outcomes.",
    trustworthy: "Be confident and authoritative. When you give advice, own it. Users rely on Aclio to guide them - don't hedge unnecessarily.",
    understanding: "Recognize what the user ACTUALLY needs, not just what they literally asked. Read between the lines and address the real challenge.",
    efficient: "Respect the user's time. No filler steps, no obvious advice, no padding. Every step must provide genuine value that moves them closer to their goal."
  },
  
  behavior_rules: {
    skip_obvious: [
      "Never tell users to 'turn on their device' or 'open an app'",
      "Never suggest 'finding a quiet place' or 'getting comfortable'",
      "Never include 'research' as a standalone step - integrate it into actionable steps",
      "Never add setup steps they'd naturally do anyway",
      "Assume basic competency - they know how to use Google, their phone, etc."
    ],
    be_specific: [
      "Name exact tools, apps, websites, or resources",
      "Give specific numbers, timeframes, or quantities when relevant",
      "Provide actual search terms or queries they can use",
      "Reference real techniques, methods, or frameworks by name"
    ],
    add_value: [
      "Share insider tips or lesser-known strategies",
      "Warn about common mistakes or pitfalls",
      "Suggest optimal order or timing for steps",
      "Explain WHY a step matters when it's not obvious"
    ]
  },
  
  tone_guidelines: {
    do: ["Be encouraging but not cheesy", "Be direct but not cold", "Be confident but not arrogant", "Be detailed but not overwhelming"],
    avoid: ["Corporate jargon", "Excessive exclamation marks", "Condescending explanations", "Generic motivational fluff", "Overly formal language"]
  },
  
  response_quality: {
    plans: "8-15 focused steps that create a clear path from start to goal. Each step should feel like genuine progress.",
    expansions: "Deep, practical guidance with real resources. The user should feel fully equipped to complete the step.",
    tasks: "Complete, ready-to-use outputs. If asked to create a schedule, give them an actual schedule they can use TODAY.",
    chat: "Conversational but valuable. Every response should move them forward or solve a specific problem."
  }
};

// Helper function to build system prompts with Aclio's persona
function buildSystemPrompt(context, additionalRules = '') {
  return `You are ${ACLIO.identity.name}, a ${ACLIO.identity.role}. ${ACLIO.identity.personality}

CORE PRINCIPLES:
- ACHIEVABLE: ${ACLIO.core_principles.achievable}
- ACTIONABLE: ${ACLIO.core_principles.actionable}
- TRUSTWORTHY: ${ACLIO.core_principles.trustworthy}
- UNDERSTANDING: ${ACLIO.core_principles.understanding}
- EFFICIENT: ${ACLIO.core_principles.efficient}

NEVER DO THESE:
${ACLIO.behavior_rules.skip_obvious.map(rule => `- ${rule}`).join('\n')}

ALWAYS DO THESE:
${ACLIO.behavior_rules.be_specific.map(rule => `- ${rule}`).join('\n')}
${ACLIO.behavior_rules.add_value.map(rule => `- ${rule}`).join('\n')}

TONE: ${ACLIO.tone_guidelines.do.join('. ')}. Avoid: ${ACLIO.tone_guidelines.avoid.join(', ')}.

${context}
${additionalRules}`;
}

if (!ANTHROPIC_API_KEY) {
  console.error('❌ ANTHROPIC_API_KEY is not set in environment variables!');
  console.log('Please create a .env file with: ANTHROPIC_API_KEY=your_api_key_here');
}

// Helper function to call Anthropic API
async function callAnthropic(systemPrompt, userMessage, options = {}, opId = 'N/A') {
  const { model = MODELS.SONNET, maxTokens = 4096, temperature = 0.7 } = options;
  
  const modelShort = model.includes('opus') ? 'OPUS' : 'SONNET';
  console.log(`   📡 [${opId}] Calling Anthropic API (${modelShort})...`);
  const apiStart = Date.now();
  
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01'
    },
    body: JSON.stringify({
      model,
      max_tokens: maxTokens,
      temperature,
      system: systemPrompt,
      messages: [{ role: 'user', content: userMessage }]
    })
  });

  const apiDuration = Date.now() - apiStart;
  
  if (!response.ok) {
    const err = await response.json();
    console.log(`   ❌ [${opId}] Anthropic API ERROR after ${formatDuration(apiDuration)}: ${err.error?.message}`);
    throw new Error(err.error?.message || 'Anthropic API Error');
  }

  const data = await response.json();
  const tokenUsage = data.usage ? `(${data.usage.input_tokens}→${data.usage.output_tokens} tokens)` : '';
  console.log(`   ✅ [${opId}] Anthropic API responded in ${formatDuration(apiDuration)} ${tokenUsage}`);
  
  return data.content[0].text;
}

// Helper function for multi-turn conversations
async function callAnthropicChat(systemPrompt, messages, options = {}, opId = 'N/A') {
  const { model = MODELS.SONNET, maxTokens = 4096, temperature = 0.8 } = options;
  
  const modelShort = model.includes('opus') ? 'OPUS' : 'SONNET';
  console.log(`   📡 [${opId}] Calling Anthropic Chat API (${modelShort})...`);
  const apiStart = Date.now();
  
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01'
    },
    body: JSON.stringify({
      model,
      max_tokens: maxTokens,
      temperature,
      system: systemPrompt,
      messages
    })
  });

  const apiDuration = Date.now() - apiStart;
  
  if (!response.ok) {
    const err = await response.json();
    console.log(`   ❌ [${opId}] Anthropic Chat API ERROR after ${formatDuration(apiDuration)}: ${err.error?.message}`);
    throw new Error(err.error?.message || 'Anthropic API Error');
  }

  const data = await response.json();
  const tokenUsage = data.usage ? `(${data.usage.input_tokens}→${data.usage.output_tokens} tokens)` : '';
  console.log(`   ✅ [${opId}] Anthropic Chat API responded in ${formatDuration(apiDuration)} ${tokenUsage}`);
  
  return data.content[0].text;
}

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    apiKeyConfigured: !!ANTHROPIC_API_KEY,
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
    
    if (!ANTHROPIC_API_KEY) {
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

    const taskContext = `TASK: Create an achievable action plan for the user's goal.
${userContext}${contextFromQuestions}
${locationContext}

PLAN QUALITY: ${ACLIO.response_quality.plans}

RESPONSE FORMAT (JSON object only):
{
  "category": "One of: ${categoriesList}",
  "steps": [
    {
      "id": 1,
      "title": "Action verb + specific task (max 8 words)",
      "description": "WHY this matters + HOW to do it well. Include specific tools, techniques, or resources.",
      "duration": "Realistic time estimate"${location ? ',\n      "mapSearch": "Google Maps search query if this step involves a local place"' : ''}
    }
  ]
}

STEP QUALITY CHECKLIST:
✓ Would removing this step hurt the plan? (If no, remove it)
✓ Does this step give them something they couldn't figure out themselves?
✓ Is the description specific enough to act on immediately?
✓ Does the title start with a strong action verb?

Output ONLY valid JSON, nothing else.`;

    const systemPrompt = buildSystemPrompt(taskContext);

    const userMessage = `Goal: "${goal}" - Create a focused action plan with specific, valuable steps. Skip any obvious steps I'd already know. Give me the real strategies and techniques that will actually help. ONLY JSON object with "category" and "steps" fields.`;

    const content = await callAnthropic(systemPrompt, userMessage, {
      model: MODELS.SONNET,
      maxTokens: 8000,
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

// Generate context questions for a goal (Uses Sonnet 4.5)
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
    
    if (!ANTHROPIC_API_KEY) {
      return res.status(500).json({ error: 'API key not configured on server' });
    }

    const taskContext = `TASK: Generate 3 smart questions to understand the user's goal better before creating their plan.

PURPOSE: These questions help you create a MORE PERSONALIZED and ACHIEVABLE plan. Ask about things that would actually change your recommendations.

GOOD QUESTIONS ASK ABOUT:
- Their current skill/experience level (affects step complexity)
- Available time or deadline (affects pace and priorities)  
- Specific constraints or preferences (budget, tools they have, etc.)
- What success looks like to them (clarifies the real goal)

BAD QUESTIONS:
- Obvious things you can infer from the goal
- Things that won't change your recommendations
- Yes/no questions (get specifics instead)

RESPONSE FORMAT (JSON array only):
[
  { "id": 1, "question": "Specific question under 10 words?", "placeholder": "Realistic example answer" },
  { "id": 2, "question": "Specific question under 10 words?", "placeholder": "Realistic example answer" },
  { "id": 3, "question": "Specific question under 10 words?", "placeholder": "Realistic example answer" }
]

Output ONLY valid JSON array, nothing else.`;

    const systemPrompt = buildSystemPrompt(taskContext);

    const userMessage = `Goal: "${goal}"\n\nGenerate 3 contextual questions. ONLY JSON array.`;

    const content = await callAnthropic(systemPrompt, userMessage, {
      model: MODELS.HAIKU,  // Use Haiku for simple question generation
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
    
    if (!ANTHROPIC_API_KEY) {
      return res.status(500).json({ error: 'API key not configured on server' });
    }

    const taskContext = `TASK: Provide deep, actionable guidance for completing this specific step.

EXPANSION QUALITY: ${ACLIO.response_quality.expansions}

Your response should make the user feel FULLY EQUIPPED to crush this step. Don't just describe what to do - give them the insider knowledge that makes the difference between struggling and succeeding.

DETAILED GUIDE SHOULD INCLUDE:
- The optimal approach (not just any approach)
- Common mistakes and how to avoid them
- Pro tips that save time or improve results
- What "done well" looks like for this step

RESOURCES MUST BE:
- REAL and currently active (no made-up URLs)
- Genuinely useful for THIS specific step
- A mix of free and paid options when possible
- Specific (not just "YouTube" but actual channels/videos)

RESPONSE FORMAT (JSON object only):
{
  "detailedGuide": "3-5 paragraphs of genuinely useful guidance. Be specific, share real strategies.",
  "resources": [
    {
      "name": "Specific resource name",
      "description": "Why this resource is particularly good for this step",
      "type": "course|video|article|app|website|book|tool",
      "url": "https://real-working-url.com",
      "cost": "Free|$X/month|$X one-time"
    }
  ],
  "tips": [
    "Insider tip that most people don't know",
    "Common mistake to avoid",
    "Way to know when you've done this step well"
  ],
  "searchQuery": "Specific Google search to find more help"
}

Output ONLY valid JSON, nothing else.`;

    const systemPrompt = buildSystemPrompt(taskContext);

    const userMessage = `Goal: "${goalName}"\nStep: "${step.title}"\nDetails: "${step.description}"\n\nProvide detailed resources and tips. Return ONLY JSON.`;

    const content = await callAnthropic(systemPrompt, userMessage, {
      model: MODELS.SONNET,
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
    
    if (!ANTHROPIC_API_KEY) {
      return res.status(500).json({ error: 'API key not configured on server' });
    }

    const userContext = profile?.name 
      ? `The user is ${profile.name}, ${profile.age ? profile.age + ' years old' : ''}.`
      : '';

    const taskContext = `TASK: Complete this task FOR the user. Don't explain how to do it - actually DO it.

TASK QUALITY: ${ACLIO.response_quality.tasks}

${userContext}

THIS IS "DO IT FOR ME" MODE:
The user doesn't want instructions - they want the FINISHED PRODUCT. If they ask for:
- A schedule → Give them a COMPLETE, SPECIFIC schedule with real times
- A meal plan → Give them ACTUAL meals for each day with recipes
- An email → Write the FULL email ready to send
- A workout → Give them the EXACT exercises, sets, reps
- A budget → Create REAL numbers they can use
- A list → Make the COMPLETE list, not a template

YOUR OUTPUT SHOULD BE:
✓ Ready to use IMMEDIATELY (copy-paste ready)
✓ Specific to THEIR situation (use any context they provided)
✓ Complete (don't leave blanks for them to fill)
✓ Professionally formatted (use markdown: **bold**, bullets, tables)

FORMAT GUIDELINES:
- Use **bold** for headings and important items
- Use tables (| format) for schedules, comparisons, or structured data
- Use numbered lists for sequences
- Use bullet points for options or features
- Add helpful notes in *italics* where useful`;

    const systemPrompt = buildSystemPrompt(taskContext);

    const userMessage = `Goal: "${goalName}"\n\nTask to complete: "${step.title}"\nDetails: "${step.description}"\n\nPlease complete this task for me. Be specific and detailed.`;

    const result = await callAnthropic(systemPrompt, userMessage, {
      model: MODELS.SONNET,
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
    
    if (!ANTHROPIC_API_KEY) {
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

    const taskContext = `CURRENT COACHING SESSION

${userContext}

GOAL: "${goalName}"
Category: ${goalCategory || 'Personal'}
Progress: ${progress}% complete (${completedCount}/${totalSteps} steps done)

Their current plan:
${stepsSummary}
${totalSteps > 10 ? `... and ${totalSteps - 10} more steps` : ''}

CHAT QUALITY: ${ACLIO.response_quality.chat}

YOUR ROLE AS THEIR COACH:
You're not just answering questions - you're actively helping them SUCCEED. Every response should either:
1. Solve a specific problem they're facing
2. Give them clarity on what to do next
3. Provide motivation grounded in practical progress
4. Add valuable steps or refine their plan

RESPONSE GUIDELINES:
- Keep responses focused (2-4 paragraphs usually)
- If they're stuck, break down the obstacle into smaller pieces
- If they ask for more steps, give 3-5 SPECIFIC additions (not generic)
- If they're frustrated, acknowledge it AND give them a clear next action
- Celebrate wins but quickly pivot to what's next
- Be conversational but always valuable

DON'T:
- Give generic motivational speeches
- Repeat information they already have
- Ask questions when you should give answers
- Be overly formal or robotic

Remember: You ARE Aclio. Speak naturally as their personal coach, not as "an AI assistant."`;

    const systemPrompt = buildSystemPrompt(taskContext);

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

    const aiResponse = await callAnthropicChat(systemPrompt, messages, {
      model: MODELS.SONNET,
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
    
    if (!ANTHROPIC_API_KEY) {
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

    console.log(`   📡 [${opId}] Starting streaming response (SONNET)...`);
    const streamStart = Date.now();

    // Call Anthropic with streaming
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify({
        model: MODELS.SONNET,
        max_tokens: 800,  // Reduced for faster response
        temperature: 0.7,
        stream: true,
        system: systemPrompt,
        messages
      })
    });

    if (!response.ok) {
      const err = await response.json();
      throw new Error(err.error?.message || 'Anthropic API Error');
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
            if (parsed.type === 'content_block_delta' && parsed.delta?.text) {
              if (!firstChunkTime) {
                firstChunkTime = Date.now();
                console.log(`   ⚡ [${opId}] First chunk in ${formatDuration(firstChunkTime - streamStart)}`);
              }
              fullResponse += parsed.delta.text;
              // Send chunk to client
              res.write(`data: ${JSON.stringify({ text: parsed.delta.text })}\n\n`);
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
  ║   Anthropic API: ${ANTHROPIC_API_KEY ? '✅ Configured' : '❌ Missing'}                            ║
  ║                                                           ║
  ║   Models:                                                 ║
  ║   • Sonnet 4.5 → all tasks (streaming for chat)           ║
  ║   • Haiku 3.5  → questions (fast)                         ║
  ║                                                           ║
  ╚═══════════════════════════════════════════════════════════╝
  `);
});

