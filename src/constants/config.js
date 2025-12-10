// App Configuration

// Backend API URL
export const API_URL = 'https://aclio-production.up.railway.app/api';

// Goal Categories
export const CATEGORIES = [
  'Health & Fitness',
  'Career',
  'Education',
  'Finance',
  'Creative',
  'Personal Growth',
  'Relationships',
  'Travel',
  'Home & Living',
  'Technology'
];

// Premium Subscription Configuration
export const PREMIUM_CONFIG = {
  FREE_GOAL_LIMIT: 3,
  FREE_DOITFORME_DAILY: 2,
  FREE_EXPAND_DAILY: 3,
  PLANS: {
    weekly: { 
      id: 'aclio_premium_weekly', 
      price: '$2.99', 
      priceNum: 2.99, 
      period: 'week' 
    },
    monthly: { 
      id: 'aclio_premium_monthly', 
      price: '$7.99', 
      priceNum: 7.99, 
      period: 'month' 
    },
    yearly: { 
      id: 'aclio_premium_yearly', 
      price: '$49.99', 
      priceNum: 49.99, 
      period: 'year', 
      isBestValue: true 
    }
  },
  FEATURES: [
    { icon: 'infinity', title: 'Unlimited Goals', desc: 'Create as many goals as you want' },
    { icon: 'wand', title: 'Unlimited "Do it for me"', desc: 'Let AI complete any task for you' },
    { icon: 'share', title: 'Share Achievements', desc: 'Beautiful celebration cards to share' },
    { icon: 'sparkles', title: 'Priority AI', desc: 'Faster, more detailed step generation' },
  ]
};

// Onboarding Slides
export const ONBOARDING_SLIDES = [
  { 
    icon: 'zap',
    iconBg: 'rgba(255, 159, 67, 0.15)',
    iconColor: '#FF9F43',
    image: 'https://em-content.zobj.net/source/apple/391/light-bulb_1f4a1.png',
    title: 'AI-Powered Goal Planning', 
    text: 'Transform your aspirations into personalized, AI-generated action plans tailored to your goals.',
    features: [
      { icon: 'sparkles', text: 'Smart guidance for any goal' },
      { icon: 'zap', text: 'Personalized action plans' },
      { icon: 'target', text: 'Tailored to your timeline' }
    ]
  },
  { 
    icon: 'check',
    iconBg: 'rgba(34, 197, 94, 0.1)',
    iconColor: '#22C55E',
    image: 'https://em-content.zobj.net/source/apple/391/clipboard_1f4cb.png',
    title: 'Step-by-Step Guidance', 
    text: 'Break down your goal into clear, manageable tasks with intelligent coaching that adapts to your progress.',
    tasks: [
      'Research industry trends', 
      'Complete an online course', 
      'Build a portfolio project',
      'Connect with mentors',
      'Apply your new skills'
    ]
  },
  { 
    icon: 'trophy',
    iconBg: 'rgba(255, 179, 71, 0.15)',
    iconColor: '#FFB347',
    image: 'https://em-content.zobj.net/source/apple/391/trophy_1f3c6.png',
    title: 'Track Your Success', 
    text: 'Celebrate milestones, stay motivated, and watch your streaks grow as you achieve your goals.',
    badge: { icon: 'trophy', text: '7-day streak unlocked' }
  },
];


