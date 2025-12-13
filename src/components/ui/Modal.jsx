// Modal Components
import { Icons } from '../../constants/icons';

export function Modal({ isOpen, onClose, children, title, className = '' }) {
  if (!isOpen) return null;

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div 
        className={`modal ${className}`} 
        onClick={e => e.stopPropagation()}
      >
        {title && (
          <div className="modal-header">
            <h2 className="modal-title">{title}</h2>
            <button className="modal-close" onClick={onClose}>
              <Icons.x />
            </button>
          </div>
        )}
        <div className="modal-content">
          {children}
        </div>
      </div>
    </div>
  );
}

export function BottomSheet({ isOpen, onClose, children, title }) {
  if (!isOpen) return null;

  return (
    <div className="bottom-sheet-backdrop" onClick={onClose}>
      <div 
        className="bottom-sheet" 
        onClick={e => e.stopPropagation()}
      >
        <div className="bottom-sheet-handle" />
        {title && (
          <div className="bottom-sheet-header">
            <h2 className="bottom-sheet-title">{title}</h2>
          </div>
        )}
        <div className="bottom-sheet-content">
          {children}
        </div>
      </div>
    </div>
  );
}

export function ConfirmModal({ isOpen, onClose, onConfirm, title, message, confirmText = 'Confirm', cancelText = 'Cancel' }) {
  if (!isOpen) return null;

  return (
    <Modal isOpen={isOpen} onClose={onClose} className="confirm-modal">
      <div className="confirm-modal-content">
        {title && <h3 className="confirm-modal-title">{title}</h3>}
        {message && <p className="confirm-modal-message">{message}</p>}
        <div className="confirm-modal-actions">
          <button className="modal-btn secondary" onClick={onClose}>
            {cancelText}
          </button>
          <button className="modal-btn primary" onClick={onConfirm}>
            {confirmText}
          </button>
        </div>
      </div>
    </Modal>
  );
}







