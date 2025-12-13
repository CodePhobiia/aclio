// Input Components

export function TextInput({ 
  value, 
  onChange, 
  placeholder, 
  type = 'text', 
  disabled = false,
  className = '',
  label,
  error
}) {
  return (
    <div className={`input-wrapper ${className}`}>
      {label && <label className="input-label">{label}</label>}
      <input
        type={type}
        className={`text-input ${error ? 'error' : ''}`}
        value={value}
        onChange={e => onChange(e.target.value)}
        placeholder={placeholder}
        disabled={disabled}
      />
      {error && <span className="input-error">{error}</span>}
    </div>
  );
}

export function TextArea({ 
  value, 
  onChange, 
  placeholder, 
  rows = 4,
  disabled = false,
  className = '',
  label 
}) {
  return (
    <div className={`input-wrapper ${className}`}>
      {label && <label className="input-label">{label}</label>}
      <textarea
        className="text-area"
        value={value}
        onChange={e => onChange(e.target.value)}
        placeholder={placeholder}
        rows={rows}
        disabled={disabled}
      />
    </div>
  );
}

export function SearchInput({ value, onChange, placeholder = 'Search...', onClear }) {
  return (
    <div className="search-input-wrapper">
      <span className="search-icon">🔍</span>
      <input
        type="text"
        className="search-input"
        value={value}
        onChange={e => onChange(e.target.value)}
        placeholder={placeholder}
      />
      {value && onClear && (
        <button className="search-clear" onClick={onClear}>×</button>
      )}
    </div>
  );
}

export function DateInput({ value, onChange, label, min, max }) {
  return (
    <div className="input-wrapper">
      {label && <label className="input-label">{label}</label>}
      <input
        type="date"
        className="date-input"
        value={value}
        onChange={e => onChange(e.target.value)}
        min={min}
        max={max}
      />
    </div>
  );
}







