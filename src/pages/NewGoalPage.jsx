// New Goal Page
import { useState, useEffect, useRef } from 'react';
import { Icons, GOAL_ICON_KEYS, ICON_COLORS } from '../constants/icons';
import { CATEGORIES } from '../constants/config';

const GENERATION_STEPS = [
  { id: 1, text: 'Understanding your goal' },
  { id: 2, text: 'Researching best practices' },
  { id: 3, text: 'Creating action steps' },
  { id: 4, text: 'Optimizing your timeline' },
  { id: 5, text: 'Finalizing your plan' },
];

export function NewGoalPage({
  onNavigate,
  onCreateGoal,
  loading,
  error,
  profile,
  location,
  questionsLoading,
  goalQuestions,
  setGoalQuestions,
  onGenerateQuestions,
  generationProgress,
}) {
  const [goalText, setGoalText] = useState('');
  const [dueDate, setDueDate] = useState('');
  const [selectedIcon, setSelectedIcon] = useState(0);
  const [selectedColor, setSelectedColor] = useState(0);
  const [showQuestions, setShowQuestions] = useState(false);
  const [animatedStep, setAnimatedStep] = useState(0);
  const intervalRef = useRef(null);
  const wasLoadingRef = useRef(false);

  // Animate through steps 1-4 with 2.5s intervals, step 5 waits for completion
  useEffect(() => {
    if (loading && !wasLoadingRef.current) {
      // Loading just started
      wasLoadingRef.current = true;
      setAnimatedStep(1);
      
      let currentStep = 1;
      intervalRef.current = setInterval(() => {
        currentStep++;
        if (currentStep <= 4) {
          setAnimatedStep(currentStep);
        } else {
          // Stop at step 4, step 5 will be set when loading completes
          clearInterval(intervalRef.current);
        }
      }, 2500);
    } else if (!loading && wasLoadingRef.current) {
      // Loading just finished - complete step 5
      wasLoadingRef.current = false;
      clearInterval(intervalRef.current);
      setAnimatedStep(5);
      
      // Reset after a short delay
      setTimeout(() => {
        setAnimatedStep(0);
      }, 500);
    }
    
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [loading]);

  // Calculate progress percentage based on animated step
  const progressPercent = loading ? Math.min((animatedStep / 5) * 100, 80) : (animatedStep === 5 ? 100 : 0);

  const suggestions = [
    "Learn a new language", 
    "Run a marathon", 
    "Start a side business", 
    "Read 20 books this year"
  ];

  const handleSubmit = async (e) => {
    e?.preventDefault();
    if (!goalText.trim() || loading) return;

    // Build additional context from answered questions
    let additionalContext = null;
    if (goalQuestions?.answers && Object.keys(goalQuestions.answers).length > 0) {
      additionalContext = Object.entries(goalQuestions.answers)
        .filter(([_, a]) => a && a.trim()) // Only include non-empty answers
        .map(([q, a]) => `${q}: ${a}`)
        .join('\n');
    }

    const goalData = {
      name: goalText,
      dueDate: dueDate || null,
      iconKey: GOAL_ICON_KEYS[selectedIcon],
      iconColor: ICON_COLORS[selectedColor],
      additionalContext: additionalContext || null,
    };

    onCreateGoal(goalData);
  };

  const handleGetQuestions = async () => {
    if (!goalText.trim()) return;
    setShowQuestions(true);
    await onGenerateQuestions(goalText);
  };

  const handleAnswerChange = (question, answer) => {
    setGoalQuestions(prev => ({
      ...prev,
      answers: { ...prev?.answers, [question]: answer }
    }));
  };

  const resetForm = () => {
    setGoalText('');
    setDueDate('');
    setSelectedIcon(0);
    setSelectedColor(0);
    setGoalQuestions(null);
    setShowQuestions(false);
    onNavigate('dashboard');
  };

  return (
    <div className="app">
      {/* Header */}
      <div className="header">
        <div className="header-left">
          <button className="header-back" onClick={resetForm}>
            <Icons.arrowLeft />
          </button>
          <span className="header-title">New Goal</span>
        </div>
      </div>

      <div className="new-goal-view">
        {/* Mascot Header */}
        <div className="new-goal-mascot-header">
          <div className="new-goal-mascot-glow" />
          <img 
            src="/Mascot face Icon.png" 
            alt="Aclio mascot" 
            className="new-goal-mascot"
          />
        </div>
        
        {/* Question Title */}
        <h1 className="new-goal-question-title">What do you want to achieve?</h1>
        
        {/* Goal Input Card */}
        <div className="new-goal-card">
          <textarea
            className="goal-input-primary"
            placeholder="e.g., Learn salsa, run a 5K..."
            value={goalText}
            onChange={(e) => setGoalText(e.target.value)}
            rows={2}
            disabled={loading}
            style={{ resize: 'none', minHeight: '56px' }}
          />
        </div>

        {/* Quick Suggestions */}
        {!goalText && (
          <div className="new-goal-section">
            <p className="suggestions-label">Quick suggestions</p>
            <div className="chips">
              {suggestions.map(s => (
                <button 
                  key={s} 
                  className="chip"
                  onClick={() => setGoalText(s)}
                >
                  {s}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Due Date */}
        <div className="new-goal-section">
          <label className="input-label">
            <Icons.calendar style={{ width: 14, height: 14, marginRight: 6, verticalAlign: 'middle' }} />
            Target completion date (optional)
          </label>
          <input
            type="date"
            className="text-input"
            value={dueDate}
            onChange={(e) => setDueDate(e.target.value)}
            min={new Date().toISOString().split('T')[0]}
          />
        </div>

        {/* Icon Selection */}
        <div className="new-goal-section">
          <label className="input-label">Choose an icon</label>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
            {GOAL_ICON_KEYS.map((key, i) => {
              const Icon = Icons[key];
              const isSelected = selectedIcon === i;
              return (
                <button
                  key={key}
                  onClick={() => setSelectedIcon(i)}
                  style={{
                    width: '44px',
                    height: '44px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    background: isSelected ? ICON_COLORS[selectedColor].bg : 'var(--bg-card)',
                    color: isSelected ? ICON_COLORS[selectedColor].color : 'var(--text-dim)',
                    border: isSelected ? `2px solid ${ICON_COLORS[selectedColor].color}` : '2px solid var(--border)',
                    borderRadius: 'var(--radius-md)',
                    cursor: 'pointer',
                    transition: 'all 0.15s',
                  }}
                >
                  <Icon />
                </button>
              );
            })}
          </div>
        </div>

        {/* Color Selection */}
        <div className="new-goal-section">
          <label className="input-label">Choose a color</label>
          <div style={{ display: 'flex', gap: '12px' }}>
            {ICON_COLORS.map((color, i) => (
              <button
                key={i}
                onClick={() => setSelectedColor(i)}
                style={{
                  width: '36px',
                  height: '36px',
                  background: color.color,
                  border: selectedColor === i ? '3px solid var(--text)' : '3px solid transparent',
                  borderRadius: '50%',
                  cursor: 'pointer',
                  transition: 'transform 0.15s',
                  transform: selectedColor === i ? 'scale(1.1)' : 'scale(1)',
                }}
              />
            ))}
          </div>
        </div>

        {/* AI Questions Card */}
        {showQuestions && goalQuestions?.questions && (
          <div className="questions-card">
            <div className="questions-header">
              <div className="questions-icon">
                <Icons.sparkles />
              </div>
              <div>
                <h3 className="questions-title">Tell us more</h3>
                <p className="questions-subtitle">Answer these to get a more personalized plan</p>
              </div>
            </div>
            {goalQuestions.questions.map((q, i) => {
              // Handle both string questions and object questions {id, question, placeholder}
              const questionText = typeof q === 'string' ? q : q.question;
              const questionKey = typeof q === 'string' ? q : q.id || i;
              const placeholder = typeof q === 'object' && q.placeholder ? q.placeholder : 'Your answer...';
              
              return (
                <div key={questionKey} className="question-item">
                  <div className="question-label">
                    <span className="question-number">{i + 1}</span>
                    <span className="question-text">{questionText}</span>
                  </div>
                  <textarea
                    className="question-input"
                    placeholder={placeholder}
                    value={goalQuestions.answers?.[questionText] || ''}
                    onChange={(e) => handleAnswerChange(questionText, e.target.value)}
                    rows={2}
                  />
                </div>
              );
            })}
          </div>
        )}

        {/* Error Message */}
        {error && (
          <div style={{ 
            padding: '12px 16px', 
            background: 'var(--red-soft)', 
            borderRadius: 'var(--radius-md)', 
            color: 'var(--red)',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            marginBottom: '16px'
          }}>
            <Icons.alertTriangle style={{ width: 18, height: 18 }} /> {error}
          </div>
        )}

        {/* Full-Screen Generation Overlay */}
        {loading && (
          <div className="generation-overlay">
            <div className="generation-content">
              <div className="generation-icon">
                <Icons.sparkles />
              </div>
              <h2 className="generation-title">Creating Your Plan</h2>
              <p className="generation-message">
                {GENERATION_STEPS[animatedStep - 1]?.text || 'Preparing your personalized action plan...'}
              </p>
              
              <div className="generation-progress-container">
                <div className="generation-progress-bar">
                  <div 
                    className="generation-progress-fill" 
                    style={{ width: `${progressPercent}%` }}
                  />
                </div>
                <p className="generation-progress-text">
                  {Math.round(progressPercent)}% complete
                </p>
              </div>
              
              <div className="generation-steps">
                {GENERATION_STEPS.map((step) => (
                  <div 
                    key={step.id}
                    className={`generation-step ${animatedStep >= step.id ? 'active' : ''} ${animatedStep > step.id ? 'done' : ''}`}
                  >
                    <div className="generation-step-icon">
                      {animatedStep > step.id ? <Icons.check /> : step.id}
                    </div>
                    <span className="generation-step-text">{step.text}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* CTA Footer */}
        <div className="cta-footer">
          {!showQuestions && goalText.trim() && !loading && (
            <button 
              className="ai-banner-card"
              onClick={handleGetQuestions}
              disabled={questionsLoading}
              style={{ width: '100%', marginBottom: '12px' }}
            >
              <div className="ai-banner-icon">
                {questionsLoading ? <Icons.refresh className="spin" /> : <Icons.sparkles />}
              </div>
              <div className="ai-banner-info">
                <div className="ai-banner-title">Personalize with questions</div>
                <div className="ai-banner-desc">Get a more tailored action plan</div>
              </div>
              <Icons.chevronRight style={{ color: 'var(--text-dim)' }} />
            </button>
          )}
          
          <button 
            className="primary-btn"
            onClick={handleSubmit}
            disabled={!goalText.trim() || loading}
          >
            {loading ? (
              <><Icons.refresh className="spin" /> Creating...</>
            ) : (
              <>
                <Icons.sparkles />
                <img src="/Mascot face Icon.png" alt="" className="primary-btn-mascot" />
                Generate Personalized Plan
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
