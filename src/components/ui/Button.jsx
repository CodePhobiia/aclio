// Button Components
import { Icons } from '../../constants/icons';

export function PrimaryButton({ children, onClick, disabled, loading, icon, className = '', style = {} }) {
  return (
    <button 
      className={`primary-btn ${className} ${loading ? 'loading' : ''}`}
      onClick={onClick}
      disabled={disabled || loading}
      style={style}
    >
      {loading ? (
        <span className="spin"><Icons.refresh /></span>
      ) : (
        <>
          {icon && <span className="btn-icon">{icon}</span>}
          {children}
        </>
      )}
    </button>
  );
}

export function SecondaryButton({ children, onClick, disabled, className = '', style = {} }) {
  return (
    <button 
      className={`secondary-btn ${className}`}
      onClick={onClick}
      disabled={disabled}
      style={style}
    >
      {children}
    </button>
  );
}

export function IconButton({ icon, onClick, className = '', style = {}, ariaLabel = '' }) {
  return (
    <button 
      className={`icon-btn ${className}`}
      onClick={onClick}
      style={style}
      aria-label={ariaLabel}
    >
      {icon}
    </button>
  );
}

export function BackButton({ onClick }) {
  return (
    <button className="header-back" onClick={onClick}>
      <Icons.arrowLeft />
    </button>
  );
}

export function FloatingActionButton({ onClick, icon, className = '' }) {
  return (
    <button className={`fab ${className}`} onClick={onClick}>
      {icon || <Icons.plus />}
    </button>
  );
}







