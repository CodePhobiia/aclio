// Welcome Screen Page
import { Icons } from '../constants/icons';

export function WelcomePage({ onGetStarted, onSignIn }) {
  return (
    <div className="app app-no-scroll">
      <div className="welcome-screen fade-in">
        <div className="welcome-content">
          {/* Flame Bunny Mascot */}
          <div className="welcome-mascot">
            <img src="/mascot.png" alt="Aclio Mascot" />
          </div>
          <h1 className="welcome-title">Aclio</h1>
          <p className="welcome-tagline">Ignite your goals.</p>
        </div>
        
        <div className="welcome-bottom">
          <button className="welcome-btn" onClick={onGetStarted}>
            Get Started
          </button>
          <p className="welcome-signin">
            Already have an account?{' '}
            <button onClick={onSignIn}>Sign in</button>
          </p>
        </div>
      </div>
    </div>
  );
}





