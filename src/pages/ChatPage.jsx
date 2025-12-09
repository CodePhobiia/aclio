// Chat Page - Talk to Aclio
import { useState, useRef, useEffect } from 'react';
import { Icons } from '../constants/icons';
import { API_URL } from '../constants/config';

export function ChatPage({
  goal,
  profile,
  onNavigate,
  isPremium,
  setShowPaywall,
}) {
  const [messages, setMessages] = useState([]);
  const [inputText, setInputText] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef(null);
  const inputRef = useRef(null);

  // Add welcome message on mount
  useEffect(() => {
    if (goal) {
      setMessages([{
        id: 1,
        role: 'assistant',
        content: `Hi! I'm Aclio, your AI goal coach! 🐰\n\nI see you're working on "${goal.name}". How can I help you today?\n\nI can:\n• Give you motivation and tips\n• Help break down your next steps\n• Answer questions about your goal\n• Suggest resources and strategies`,
        timestamp: new Date(),
      }]);
    } else {
      setMessages([{
        id: 1,
        role: 'assistant',
        content: `Hi! I'm Aclio, your AI goal coach! 🐰\n\nHow can I help you achieve your goals today?\n\nI can:\n• Give you motivation and tips\n• Help you plan your next steps\n• Answer questions\n• Suggest strategies`,
        timestamp: new Date(),
      }]);
    }
  }, [goal]);

  // Scroll to bottom when new messages arrive
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSend = async () => {
    if (!inputText.trim() || isLoading) return;

    const userMessage = {
      id: Date.now(),
      role: 'user',
      content: inputText.trim(),
      timestamp: new Date(),
    };

    setMessages(prev => [...prev, userMessage]);
    setInputText('');
    setIsLoading(true);

    // Create placeholder for streaming response
    const assistantMessageId = Date.now() + 1;
    setMessages(prev => [...prev, {
      id: assistantMessageId,
      role: 'assistant',
      content: '',
      timestamp: new Date(),
      isStreaming: true,
    }]);

    try {
      // Build chat history (exclude welcome message)
      const chatHistory = messages.slice(1).map(m => ({
        role: m.role,
        content: m.content,
      }));

      // Use streaming endpoint for instant response feel
      const response = await fetch(`${API_URL}/talk-to-aclio-stream`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          goalName: goal?.name || 'General',
          goalCategory: goal?.category || 'Personal',
          steps: goal?.steps || [],
          completedSteps: goal?.completedSteps || [],
          message: userMessage.content,
          chatHistory: chatHistory.slice(-4), // Last 4 messages for speed
          profile: profile || null,
        }),
      });

      if (!response.ok) throw new Error('Failed to get response');

      // Read the stream
      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let fullContent = '';

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        const chunk = decoder.decode(value);
        const lines = chunk.split('\n');

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            try {
              const data = JSON.parse(line.slice(6));
              if (data.text) {
                fullContent += data.text;
                // Update the streaming message
                setMessages(prev => prev.map(m => 
                  m.id === assistantMessageId 
                    ? { ...m, content: fullContent }
                    : m
                ));
              }
              if (data.done) {
                // Mark streaming as complete
                setMessages(prev => prev.map(m => 
                  m.id === assistantMessageId 
                    ? { ...m, isStreaming: false }
                    : m
                ));
              }
              if (data.error) {
                throw new Error(data.error);
              }
            } catch (e) {
              // Skip non-JSON lines
            }
          }
        }
      }

      // Ensure we have content
      if (!fullContent) {
        setMessages(prev => prev.map(m => 
          m.id === assistantMessageId 
            ? { ...m, content: "I'm here to help! Could you tell me more?", isStreaming: false }
            : m
        ));
      }
    } catch (error) {
      console.error('Chat error:', error);
      setMessages(prev => prev.map(m => 
        m.id === assistantMessageId 
          ? { ...m, content: "I'm having trouble connecting right now. Please try again in a moment! 🐰", isStreaming: false }
          : m
      ));
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const quickPrompts = goal ? [
    "Give me motivation",
    "What should I focus on?",
    "How do I stay consistent?",
    "Tips for this step",
  ] : [
    "Help me set a goal",
    "Give me motivation",
    "How do I stay consistent?",
    "Tips for productivity",
  ];

  return (
    <div className="app">
      {/* Header */}
      <div className="chat-header">
        <button className="header-back" onClick={() => onNavigate(goal ? 'detail' : 'dashboard')}>
          <Icons.arrowLeft />
        </button>
        <div className="chat-header-info">
          <img src="/Mascot face Icon.png" alt="Aclio" className="chat-header-avatar" />
          <div className="chat-header-text">
            <span className="chat-header-name">Aclio</span>
            <span className="chat-header-status">Your AI Goal Coach</span>
          </div>
        </div>
      </div>

      {/* Messages */}
      <div className="chat-messages">
        {messages.map((message) => (
          <div 
            key={message.id} 
            className={`chat-message ${message.role === 'user' ? 'user' : 'assistant'}`}
          >
            {message.role === 'assistant' && (
              <div className="chat-message-avatar">
                <img src="/Mascot face Icon.png" alt="Aclio" />
              </div>
            )}
            <div className="chat-message-bubble">
              <p className="chat-message-text">{message.content}</p>
            </div>
          </div>
        ))}
        
        {isLoading && (
          <div className="chat-message assistant">
            <div className="chat-message-avatar">
              <img src="/Mascot face Icon.png" alt="Aclio" />
            </div>
            <div className="chat-message-bubble">
              <div className="chat-typing">
                <span></span>
                <span></span>
                <span></span>
              </div>
            </div>
          </div>
        )}
        
        <div ref={messagesEndRef} />
      </div>

      {/* Quick Prompts */}
      {messages.length <= 1 && (
        <div className="chat-quick-prompts">
          {quickPrompts.map((prompt, i) => (
            <button 
              key={i}
              className="chat-quick-prompt"
              onClick={() => {
                setInputText(prompt);
                inputRef.current?.focus();
              }}
            >
              {prompt}
            </button>
          ))}
        </div>
      )}

      {/* Input Area */}
      <div className="chat-input-area">
        <div className="chat-input-container">
          <textarea
            ref={inputRef}
            className="chat-input"
            placeholder="Ask Aclio anything..."
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            onKeyPress={handleKeyPress}
            rows={1}
          />
          <button 
            className={`chat-send-btn ${inputText.trim() ? 'active' : ''}`}
            onClick={handleSend}
            disabled={!inputText.trim() || isLoading}
          >
            <Icons.send />
          </button>
        </div>
      </div>
    </div>
  );
}

