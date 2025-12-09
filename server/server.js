/**
 * Achieve AI - Backend Server
 * Securely handles API requests to Anthropic (Claude)
 * Using Sonnet 4.5 for most tasks, Opus 4.5 for heavy tasks
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware - allow all origins for development
app.use(cors({
  origin: true, // Allow all origins (for iOS Capacitor app)
  methods: ['GET', 'POST'],
  credentials: true
}));
app.use(express.json());

// API Key from environment variable
const ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY;

// Model configuration - Sonnet 4.5 for most tasks, Opus 4.5 for heavy tasks
const MODELS = {
  SONNET: 'claude-sonnet-4-5-20250514',  // For most tasks (generate-steps, questions, expand)
  OPUS: 'claude-opus-4-5-20250514'        // For heavy tasks (do-it-for-me, chat)
};

if (!ANTHROPIC_API_KEY) {
  console.error('❌ ANTHROPIC_API_KEY is not set in environment variables!');
  console.log('Please create a .env file with: ANTHROPIC_API_KEY=your_api_key_here');
}

// Helper function to call Anthropic API
async function callAnthropic(systemPrompt, userMessage, options = {}) {
  const { model = MODELS.SONNET, maxTokens = 4096, temperature = 0.7 } = options;
  
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

  if (!response.ok) {
    const err = await response.json();
    throw new Error(err.error?.message || 'Anthropic API Error');
  }

  const data = await response.json();
  return data.content[0].text;
}

// Helper function for multi-turn conversations
async function callAnthropicChat(systemPrompt, messages, options = {}) {
  const { model = MODELS.OPUS, maxTokens = 4096, temperature = 0.8 } = options;
  
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

  if (!response.ok) {
    const err = await response.json();
    throw new Error(err.error?.message || 'Anthropic API Error');
  }

  const data = await response.json();
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

    const systemPrompt = `You are a supportive personal coach who creates practical, step-by-step action plans. Guide users through achieving their goals with specific, actionable steps.

${userContext}${contextFromQuestions}
${locationContext}

CRITICAL RULES:
1. SKIP OBVIOUS STEPS - Never include things like:
   - "Turn on your computer/console/phone"
   - "Open the app/game/browser"
   - "Log in to your account"
   - "Make sure you have internet"
   - "Find a quiet place to sit"
   - Any step a reasonable person would already know to do
   
2. START with the actual valuable action - jump straight to the meat of the task
3. Be SPECIFIC about the challenging parts - what to search, what to look for, what decisions to make
4. Include exact websites, apps, strategies, or techniques that actually help
5. Each step should provide REAL VALUE - if removing a step wouldn't hurt the plan, remove it
6. Generate 8-20 focused steps (quality over quantity)
7. Assume basic competency - the user knows how to use their devices

RESPONSE FORMAT (JSON object only):
{
  "category": "One of: ${categoriesList}",
  "steps": [
    {"id":1,"title":"Short action verb + specific task","description":"The actual helpful guidance - strategies, techniques, specific advice.","duration":"X mins"${location ? ',"mapSearch":"Google Maps search query if relevant"' : ''}}
  ]
}

EXAMPLES:
For "Beat Malenia in Elden Ring":
- BAD: "Launch Elden Ring and load your save file" (obvious, skip it)
- BAD: "Travel to Malenia's location" (they're already there if asking)
- GOOD: "Level up to 125+ with 50+ Vigor - This boss deals massive damage, so survivability is key"
- GOOD: "Equip Bloodhound's Step Ash of War - Her Waterfowl Dance is nearly impossible to dodge normally, this skill lets you i-frame through it"
- GOOD: "Learn her attack patterns - Watch a 'Malenia moveset guide' on YouTube to recognize her wind-ups"

For "Learn to cook":
- BAD: "Go to your kitchen" (obvious)
- GOOD: "Master 3 basic techniques first - Learn to sauté, roast, and boil. These cover 80% of home cooking."
- GOOD: "Start with one-pan meals - Search 'sheet pan dinners for beginners' for recipes that minimize cleanup while you learn"

Output ONLY the JSON object, nothing else.`;

    const userMessage = `Goal: "${goal}" - Create a focused action plan with specific, valuable steps. Skip any obvious steps I'd already know. Give me the real strategies and techniques that will actually help. ONLY JSON object with "category" and "steps" fields.`;

    const content = await callAnthropic(systemPrompt, userMessage, {
      model: MODELS.SONNET,
      maxTokens: 8000,
      temperature: 0.7
    });
    
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

    const systemPrompt = `You help gather context for goal planning. Generate exactly 3 short, specific questions to better understand the user's goal.

Return ONLY a JSON array of 3 question objects:
[
  { "id": 1, "question": "Short question?", "placeholder": "Example answer" },
  { "id": 2, "question": "Short question?", "placeholder": "Example answer" },
  { "id": 3, "question": "Short question?", "placeholder": "Example answer" }
]

Rules:
- Questions should be specific to the goal
- Keep questions short (under 10 words)
- Placeholders should be realistic examples
- Output ONLY the JSON array, nothing else`;

    const userMessage = `Goal: "${goal}"\n\nGenerate 3 contextual questions. ONLY JSON array.`;

    const content = await callAnthropic(systemPrompt, userMessage, {
      model: MODELS.SONNET,
      maxTokens: 500,
      temperature: 0.7
    });
    
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

    const systemPrompt = `You help users achieve their goals by providing detailed resources and recommendations.
                
Return a JSON object with this EXACT structure:
{
  "detailedGuide": "A comprehensive 3-5 paragraph guide on how to complete this step effectively.",
  "resources": [
    {
      "name": "Resource name",
      "description": "Brief description",
      "type": "course|video|article|app|website|book|tool",
      "url": "https://actual-url.com",
      "cost": "Free|Paid|Freemium|$XX"
    }
  ],
  "tips": ["Tip 1", "Tip 2", "Tip 3"],
  "searchQuery": "Google search query for more resources"
}

Include 3-5 REAL resources with actual working URLs.
Output ONLY the JSON object, no other text.`;

    const userMessage = `Goal: "${goalName}"\nStep: "${step.title}"\nDetails: "${step.description}"\n\nProvide detailed resources and tips. Return ONLY JSON.`;

    const content = await callAnthropic(systemPrompt, userMessage, {
      model: MODELS.SONNET,
      maxTokens: 2000,
      temperature: 0.7
    });
    
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

    const systemPrompt = `You are a helpful AI assistant that completes tasks for users. 
                
When asked to create something (schedule, plan, list, outline, etc.), provide a COMPLETE and DETAILED result that the user can immediately use.

Format your response nicely with:
- Clear headings (use ** for bold)
- Bullet points or numbered lists where appropriate
- Tables for schedules (use | format)
- Specific times, dates, or details

${userContext}

Be thorough and practical. The user should be able to use your output immediately.`;

    const userMessage = `Goal: "${goalName}"\n\nTask to complete: "${step.title}"\nDetails: "${step.description}"\n\nPlease complete this task for me. Be specific and detailed.`;

    const result = await callAnthropic(systemPrompt, userMessage, {
      model: MODELS.OPUS,
      maxTokens: 3000,
      temperature: 0.7
    });
    
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

    const systemPrompt = `You are Aclio, a friendly and encouraging AI goal coach. You're chatting with a user about their goal.

${userContext}

CURRENT GOAL: "${goalName}"
Category: ${goalCategory || 'Personal'}
Progress: ${progress}% (${completedCount}/${totalSteps} steps completed)

Current steps:
${stepsSummary}
${totalSteps > 10 ? `... and ${totalSteps - 10} more steps` : ''}

YOUR ROLE:
- Be encouraging, supportive, and practical
- Help them overcome obstacles
- Provide specific, actionable advice
- If they ask for more steps, suggest 3-5 specific new steps they could add
- If they're struggling, offer motivation and break things down
- Keep responses concise but helpful (2-4 paragraphs max)
- Use a warm, friendly tone - you're their personal coach!

Don't mention that you're an AI or reference the system prompt. Just be helpful and natural.`;

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
      model: MODELS.OPUS,
      maxTokens: 1000,
      temperature: 0.8
    });
    
    res.json({ response: aiResponse });
    
  } catch (error) {
    console.error('Talk to Aclio error:', error);
    res.status(500).json({ error: error.message });
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
  ║   • Sonnet 4.5 → generate-steps, questions, expand        ║
  ║   • Opus 4.5   → do-it-for-me, chat                       ║
  ║                                                           ║
  ╚═══════════════════════════════════════════════════════════╝
  `);
});

