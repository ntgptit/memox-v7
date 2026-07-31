import React from 'react';
import { MxIcon } from '../core/MxIcon.jsx';

/**
 * The mobile action menu. It decides nothing: which actions exist and whether
 * each is available arrives as a list. An unavailable row stays visible and grey
 * — hiding it makes the menu change shape between visits.
 */
export function MxActionSheet({ actions, title, onDismiss }) {
  return (
    <div className="mx-scrim mx-scrim--bottom" role="dialog" aria-modal="true" aria-label={title} onClick={onDismiss}>
      <div className="mx-sheet" onClick={(e) => e.stopPropagation()}>
        <div className="mx-sheet__handle" />
        {title ? <p className="mx-sheet__title">{title}</p> : null}
        {actions.map((a) => {
          const destructive = a.variant === 'destructive';
          const classes = ['mx-tile', destructive ? 'mx-sheet__row--destructive' : '', a.isEnabled === false ? 'mx-tile--disabled' : ''].filter(Boolean).join(' ');
          const inner = (
            <>
              {a.icon ? <span className="mx-tile__icon" style={destructive ? { color: 'var(--color-danger)' } : undefined}><MxIcon name={a.icon} /></span> : null}
              <span className="mx-tile__title">{a.label}</span>
            </>
          );
          return a.isEnabled === false
            ? <div key={a.label} className={classes}>{inner}</div>
            : <button key={a.label} type="button" className={classes} onClick={a.onPress}>{inner}</button>;
        })}
      </div>
    </div>
  );
}
