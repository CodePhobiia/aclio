import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Target, Check, Loader2, Sparkles, RotateCcw, Clock, ChevronRight } from 'lucide-react'

// ⚠️ Replace with your Groq API key from console.groq.com
const GROQ_API_KEY = 'YOUR_GROQ_API_KEY_HERE'

const generateSteps = async (goal) => {
  const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${GROQ_API_KEY}`
    },
    body: JSON.stringify({
      model: 'llama-3.1-70b-versatile',
      messages: [
        { 
          role: 'system', 
          content: `You are a goal coach. Create 6-8 actionable steps. Return ONLY a JSON array like this:
[{"id":1,"title":"Step title","description":"One sentence how to do it","duration":"15 min"}]
No other text, just the JSON array.`
        },
        { role: 'user', content: `Create steps to: ${goal}` }
      ],
      temperature: 0.7,
      max_tokens: 1500
    })
  })

  if (!response.ok) throw new Error('API request failed')
  
  const data = await response.json()
  let content = data.choices[0].message.content.trim()
  if (content.startsWith('```')) {
    content = content.replace(/```json\n?/g, '').replace(/```\n?/g, '')
  }
  return JSON.parse(content)
}

export default function App() {
  const [goal, setGoal] = useState('')
  const [steps, setSteps] = useState([])
  const [completed, setCompleted] = useState(new Set())
  const [loading, setLoading] = useState(false)
  const [view, setView] = useState('home')
  const [error, setError] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!goal.trim() || loading) return
    
    setLoading(true)
    setError('')
    
    try {
      const result = await generateSteps(goal)
      setSteps(result)
      setCompleted(new Set())
      setView('results')
    } catch (err) {
      setError('Failed to generate. Check your API key.')
    } finally {
      setLoading(false)
    }
  }

  const toggle = (id) => {
    setCompleted(prev => {
      const next = new Set(prev)
      next.has(id) ? next.delete(id) : next.add(id)
      return next
    })
  }

  const reset = () => {
    setGoal('')
    setSteps([])
    setCompleted(new Set())
    setView('home')
  }

  const progress = steps.length ? Math.round((completed.size / steps.length) * 100) : 0

  const styles = {
    app: { minHeight: '100vh', padding: '20px', maxWidth: '500px', margin: '0 auto' },
    header: { display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '40px', paddingTop: '20px' },
    logo: { width: '44px', height: '44px', background: 'var(--accent)', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' },
    title: { fontSize: '22px', fontWeight: '700' },
    hero: { fontSize: '34px', fontWeight: '700', lineHeight: '1.15', marginBottom: '12px' },
    subtitle: { color: 'var(--text-dim)', fontSize: '17px', marginBottom: '32px' },
    input: { width: '100%', padding: '18px', background: 'var(--card)', border: 'none', borderRadius: '14px', color: 'var(--text)', fontSize: '17px', marginBottom: '16px', outline: 'none' },
    btn: { width: '100%', padding: '18px', background: 'var(--accent)', border: 'none', borderRadius: '14px', color: '#fff', fontSize: '17px', fontWeight: '600', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '10px' },
    chips: { display: 'flex', flexWrap: 'wrap', gap: '10px', marginTop: '32px' },
    chip: { padding: '10px 16px', background: 'var(--card)', border: 'none', borderRadius: '100px', color: 'var(--text)', fontSize: '15px', cursor: 'pointer' },
    error: { color: '#ff453a', textAlign: 'center', marginTop: '16px' },
    backBtn: { width: '44px', height: '44px', background: 'var(--card)', border: 'none', borderRadius: '50%', color: 'var(--text)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' },
    goalText: { flex: '1' },
    goalLabel: { fontSize: '13px', color: 'var(--text-dim)', textTransform: 'uppercase' },
    goalTitle: { fontSize: '20px', fontWeight: '600', marginTop: '4px' },
    progressBar: { height: '6px', background: 'var(--card)', borderRadius: '100px', margin: '20px 0', overflow: 'hidden' },
    progressFill: { height: '100%', background: 'var(--accent)', borderRadius: '100px' },
    progressInfo: { display: 'flex', justifyContent: 'space-between', color: 'var(--text-dim)', fontSize: '14px' },
    stepCard: { display: 'flex', alignItems: 'flex-start', gap: '16px', padding: '18px', background: 'var(--card)', borderRadius: '14px', marginBottom: '12px', cursor: 'pointer', border: 'none', width: '100%', textAlign: 'left' },
    checkbox: { width: '26px', height: '26px', borderRadius: '50%', background: 'rgba(120,120,128,0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: '0' },
    checked: { background: 'var(--success)' },
    stepContent: { flex: '1' },
    stepNum: { fontSize: '12px', color: 'var(--accent)', fontWeight: '600', textTransform: 'uppercase' },
    stepTitle: { fontSize: '17px', fontWeight: '600', margin: '4px 0 6px' },
    stepDesc: { fontSize: '15px', color: 'var(--text-dim)', lineHeight: '1.4' },
    stepDur: { fontSize: '13px', color: 'var(--text-dim)', marginTop: '10px', display: 'flex', alignItems: 'center', gap: '5px' },
    done: { padding: '32px', background: 'linear-gradient(135deg, var(--success), #28a745)', borderRadius: '20px', textAlign: 'center', marginTop: '20px' },
    doneEmoji: { fontSize: '48px', marginBottom: '16px' },
    doneTitle: { fontSize: '24px', fontWeight: '700', marginBottom: '8px' },
    doneText: { opacity: '0.9', marginBottom: '24px' },
    doneBtn: { padding: '14px 28px', background: '#fff', border: 'none', borderRadius: '12px', color: 'var(--success)', fontWeight: '600', cursor: 'pointer' }
  }

  const suggestions = ["Learn a new language", "Get fit in 30 days", "Start a side hustle", "Read more books"]

  return (
    <div style={styles.app}>
      <AnimatePresence mode="wait">
        {view === 'home' ? (
          <motion.div key="home" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0, x: -50 }}>
            <div style={styles.header}>
              <div style={styles.logo}><Target size={24} /></div>
              <span style={styles.title}>Achieve AI</span>
            </div>
            
            <h1 style={styles.hero}>What do you want to achieve?</h1>
            <p style={styles.subtitle}>AI will create your personalized roadmap</p>
            
            <form onSubmit={handleSubmit}>
              <input 
                style={styles.input} 
                placeholder="Enter your goal..." 
                value={goal} 
                onChange={e => setGoal(e.target.value)}
                disabled={loading}
              />
              <button style={{...styles.btn, opacity: (!goal.trim() || loading) ? 0.5 : 1}} disabled={!goal.trim() || loading}>
                {loading ? <Loader2 size={22} className="spin" /> : <><Sparkles size={20}/> Generate Plan</>}
              </button>
            </form>
            
            {error && <p style={styles.error}>{error}</p>}
            
            <div style={styles.chips}>
              {suggestions.map(s => (
                <button key={s} style={styles.chip} onClick={() => setGoal(s)}>{s}</button>
              ))}
            </div>
          </motion.div>
        ) : (
          <motion.div key="results" initial={{ opacity: 0, x: 50 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0 }}>
            <div style={{...styles.header, marginBottom: '20px'}}>
              <button style={styles.backBtn} onClick={reset}><RotateCcw size={20}/></button>
              <div style={styles.goalText}>
                <div style={styles.goalLabel}>Your Goal</div>
                <div style={styles.goalTitle}>{goal}</div>
              </div>
            </div>
            
            <div style={styles.progressInfo}>
              <span>{completed.size} of {steps.length} done</span>
              <span style={{color: 'var(--accent)', fontWeight: '600'}}>{progress}%</span>
            </div>
            <div style={styles.progressBar}>
              <motion.div style={styles.progressFill} initial={{width: 0}} animate={{width: `${progress}%`}} />
            </div>
            
            {steps.map((step, i) => (
              <motion.button 
                key={step.id} 
                style={{...styles.stepCard, opacity: completed.has(step.id) ? 0.6 : 1}}
                onClick={() => toggle(step.id)}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.08 }}
              >
                <div style={{...styles.checkbox, ...(completed.has(step.id) ? styles.checked : {})}}>
                  {completed.has(step.id) && <Check size={14} strokeWidth={3} />}
                </div>
                <div style={styles.stepContent}>
                  <div style={styles.stepNum}>Step {step.id}</div>
                  <div style={{...styles.stepTitle, textDecoration: completed.has(step.id) ? 'line-through' : 'none'}}>{step.title}</div>
                  <div style={styles.stepDesc}>{step.description}</div>
                  <div style={styles.stepDur}><Clock size={12}/> {step.duration}</div>
                </div>
                <ChevronRight size={20} color="var(--text-dim)" />
              </motion.button>
            ))}
            
            {progress === 100 && (
              <motion.div style={styles.done} initial={{scale: 0.9, opacity: 0}} animate={{scale: 1, opacity: 1}}>
                <div style={styles.doneEmoji}>🎉</div>
                <div style={styles.doneTitle}>Amazing work!</div>
                <div style={styles.doneText}>You've completed all steps!</div>
                <button style={styles.doneBtn} onClick={reset}>Set New Goal</button>
              </motion.div>
            )}
          </motion.div>
        )}
      </AnimatePresence>
      
      <style>{`.spin { animation: spin 1s linear infinite; } @keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </div>
  )
}

