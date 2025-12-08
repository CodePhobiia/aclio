/**
 * Achieve AI - Backend Server
 * Securely handles API requests to Groq
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors({
  origin: ['http://localhost:8080', 'http://localhost:3000', 'http://127.0.0.1:8080'],
  methods: ['GET', 'POST'],
  credentials: true
}));
app.use(express.json());

// API Key from environment variable
const GROQ_API_KEY = process.env.GROQ_API_KEY;

if (!GROQ_API_KEY) {
  console.error('❌ GROQ_API_KEY is not set in environment variables!');
  console.log('Please create a .env file with: GROQ_API_KEY=your_api_key_here');
}

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    apiKeyConfigured: !!GROQ_API_KEY
  });
});

// Generate steps for a goal
app.post('/api/generate-steps', async (req, res) => {
  try {
    const { goal, profile, location, additionalContext, categories } = req.body;
    
    if (!goal) {
      return res.status(400).json({ error: 'Goal is required' });
    }
    
    if (!GROQ_API_KEY) {
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

    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json', 
        'Authorization': `Bearer ${GROQ_API_KEY}` 
      },
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        messages: [
          { 
            role: 'system', 
            content: `You are a supportive personal coach who creates HIGHLY DETAILED, step-by-step action plans. Your job is to hold the user's hand and guide them through every small action needed to achieve their goal.

${userContext}${contextFromQuestions}
${locationContext}

CRITICAL RULES:
1. Break everything down into SMALL, IMMEDIATELY ACTIONABLE steps
2. Each step should take 5-30 minutes to complete (rarely longer)
3. Be SPECIFIC - instead of "research options", say "Open Google and search for [specific query]"
4. Include exact websites, apps, or tools to use
5. Tell them exactly what to look for, what to write down, what to click
6. Assume they know NOTHING - explain every detail
7. Each step should have ONE clear action, not multiple tasks
8. Generate 20-40 steps depending on goal complexity
9. Make the user feel guided and supported, never overwhelmed

RESPONSE FORMAT (JSON object only):
{
  "category": "One of: ${categoriesList}",
  "steps": [
    {"id":1,"title":"Short action verb + specific task","description":"Exactly what to do, where to go, what to click/write/say. Be specific and encouraging.","duration":"X mins"${location ? ',"mapSearch":"Google Maps search query if relevant"' : ''}}
  ]
}

EXAMPLE of good granular steps for "Learn Guitar":
- BAD: "Buy a guitar" (too broad)
- GOOD: "Research beginner guitars online - Open guitarworld.com/best-beginner-guitars and read through the top 5 recommendations. Write down 2-3 options in your price range."
- GOOD: "Watch a guitar size guide - Search YouTube for 'how to choose guitar size beginners' and watch one video to understand what size fits you."
- GOOD: "Set your budget - Decide how much you can spend. For beginners, $100-200 is enough for a decent acoustic guitar."

Output ONLY the JSON object, nothing else.` 
          },
          { 
            role: 'user', 
            content: `Goal: "${goal}" - Create a comprehensive, hand-holding action plan with many small, specific steps. Guide me like I'm a complete beginner. ONLY JSON object with "category" and "steps" fields.` 
          }
        ],
        temperature: 0.7,
        max_tokens: 8000
      })
    });

    if (!response.ok) {
      const err = await response.json();
      throw new Error(err.error?.message || 'API Error');
    }

    const data = await response.json();
    let content = data.choices[0].message.content.trim();
    if (content.startsWith('```')) {
      content = content.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    }
    
    const result = JSON.parse(content);
    res.json(result);
    
  } catch (error) {
    console.error('Generate steps error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Generate context questions for a goal
app.post('/api/generate-questions', async (req, res) => {
  try {
    const { goal } = req.body;
    
    if (!goal) {
      return res.status(400).json({ error: 'Goal is required' });
    }
    
    if (!GROQ_API_KEY) {
      return res.status(500).json({ error: 'API key not configured on server' });
    }

    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json', 
        'Authorization': `Bearer ${GROQ_API_KEY}` 
      },
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        messages: [
          { 
            role: 'system', 
            content: `You help gather context for goal planning. Generate exactly 3 short, specific questions to better understand the user's goal.

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
- Output ONLY the JSON array, nothing else` 
          },
          { 
            role: 'user', 
            content: `Goal: "${goal}"\n\nGenerate 3 contextual questions. ONLY JSON array.` 
          }
        ],
        temperature: 0.7,
        max_tokens: 500
      })
    });

    if (!response.ok) {
      const err = await response.json();
      throw new Error(err.error?.message || 'API Error');
    }

    const data = await response.json();
    let content = data.choices[0].message.content.trim();
    if (content.startsWith('```')) {
      content = content.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    }
    
    const questions = JSON.parse(content);
    res.json({ questions });
    
  } catch (error) {
    console.error('Generate questions error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Expand step with resources
app.post('/api/expand-step', async (req, res) => {
  try {
    const { goalName, step } = req.body;
    
    if (!step) {
      return res.status(400).json({ error: 'Step is required' });
    }
    
    if (!GROQ_API_KEY) {
      return res.status(500).json({ error: 'API key not configured on server' });
    }

    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json', 
        'Authorization': `Bearer ${GROQ_API_KEY}` 
      },
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        messages: [
          { 
            role: 'system', 
            content: `You help users achieve their goals by providing detailed resources and recommendations.
                
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
Output ONLY the JSON object, no other text.` 
          },
          { 
            role: 'user', 
            content: `Goal: "${goalName}"\nStep: "${step.title}"\nDetails: "${step.description}"\n\nProvide detailed resources and tips. Return ONLY JSON.` 
          }
        ],
        temperature: 0.7,
        max_tokens: 2000
      })
    });

    if (!response.ok) {
      const err = await response.json();
      throw new Error(err.error?.message || 'API Error');
    }

    const data = await response.json();
    let content = data.choices[0].message.content.trim();
    if (content.startsWith('```')) {
      content = content.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    }
    
    const result = JSON.parse(content);
    res.json(result);
    
  } catch (error) {
    console.error('Expand step error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Do it for me - AI completes the task
app.post('/api/do-it-for-me', async (req, res) => {
  try {
    const { goalName, step, profile } = req.body;
    
    if (!step) {
      return res.status(400).json({ error: 'Step is required' });
    }
    
    if (!GROQ_API_KEY) {
      return res.status(500).json({ error: 'API key not configured on server' });
    }

    const userContext = profile?.name 
      ? `The user is ${profile.name}, ${profile.age ? profile.age + ' years old' : ''}.`
      : '';

    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json', 
        'Authorization': `Bearer ${GROQ_API_KEY}` 
      },
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        messages: [
          { 
            role: 'system', 
            content: `You are a helpful AI assistant that completes tasks for users. 
                
When asked to create something (schedule, plan, list, outline, etc.), provide a COMPLETE and DETAILED result that the user can immediately use.

Format your response nicely with:
- Clear headings (use ** for bold)
- Bullet points or numbered lists where appropriate
- Tables for schedules (use | format)
- Specific times, dates, or details

${userContext}

Be thorough and practical. The user should be able to use your output immediately.` 
          },
          { 
            role: 'user', 
            content: `Goal: "${goalName}"\n\nTask to complete: "${step.title}"\nDetails: "${step.description}"\n\nPlease complete this task for me. Be specific and detailed.` 
          }
        ],
        temperature: 0.7,
        max_tokens: 3000
      })
    });

    if (!response.ok) {
      const err = await response.json();
      throw new Error(err.error?.message || 'API Error');
    }

    const data = await response.json();
    const result = data.choices[0].message.content;
    res.json({ result });
    
  } catch (error) {
    console.error('Do it for me error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`
  ╔═══════════════════════════════════════════════╗
  ║                                               ║
  ║   🎯 Achieve AI Server                        ║
  ║                                               ║
  ║   Server running on http://localhost:${PORT}    ║
  ║   API Key: ${GROQ_API_KEY ? '✅ Configured' : '❌ Missing'}                     ║
  ║                                               ║
  ╚═══════════════════════════════════════════════╝
  `);
});

