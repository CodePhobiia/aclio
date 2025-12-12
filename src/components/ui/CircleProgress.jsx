// Circular Progress Indicator Component

export function CircleProgress({ percent, size = 64, stroke = 5 }) {
  const radius = (size - stroke) / 2;
  const circ = radius * 2 * Math.PI;
  const offset = circ - (percent / 100) * circ;

  return (
    <svg width={size} height={size} className="circle-progress">
      <circle 
        cx={size / 2} 
        cy={size / 2} 
        r={radius} 
        fill="none" 
        stroke="var(--border)" 
        strokeWidth={stroke} 
      />
      <circle 
        cx={size / 2} 
        cy={size / 2} 
        r={radius} 
        fill="none" 
        stroke="var(--accent)" 
        strokeWidth={stroke} 
        strokeDasharray={circ} 
        strokeDashoffset={offset} 
        strokeLinecap="round"
        style={{ 
          transform: 'rotate(-90deg)', 
          transformOrigin: 'center',
          transition: 'stroke-dashoffset 0.5s ease'
        }}
      />
    </svg>
  );
}





