import React from 'react';
import { MxIcon } from '../core/MxIcon.jsx';

/**
 * The mobile action menu. It decides nothing: which actions exist and whether
 * each is available arrives as a list. An unavailable row stays visible and grey
 * — hiding it makes the menu change shape between visits.
 *
 * `isSelected` marks the row the app is already in, for a sheet that CHOOSES
 * rather than acts — a list of sort orders is still a list of actions, but one
 * of them is where the user already is, and a sheet that does not say which
 * turns "change the order" into "guess the order". It draws a trailing check in
 * the brand ink and sets aria-checked, so the fact does not live in the tick
 * alone.
 */
export function MxActionSheet({ actions, title, onDismiss }) {
  return (
    <div className="mx-scrim mx-scrim--bottom" role="dialog" aria-modal="true" aria-label={title} onClick={onDismiss}>
      <div className="mx-sheet" onClick={(e) => e.stopPropagation()}>
        <div className="mx-sheet__handle" />
        {title ? <p className="mx-sheet__title">{title}</p> : null}
        {actions.map((a) => {
          const destructive = a.variant === 'destructive';
          const classes = ['mx-tile', destructive ? 'mx-sheet__row--destructive' : '', a.isEnabled === false ? 'mx-tile--disabled' : '', a.isSelected ? 'mx-tile--selected' : ''].filter(Boolean).join(' ');
          const inner = (
            <>
              {a.icon ? <span className="mx-tile__icon" style={destructive ? { color: 'var(--color-danger)' } : undefined}><MxIcon name={a.icon} /></span> : null}
              <span className="mx-tile__title">{a.label}</span>
              {a.isSelected ? <span className="mx-tile__check"><MxIcon name="check" /></span> : null}
            </>
          );
          return a.isEnabled === false
            ? <div key={a.label} className={classes}>{inner}</div>
            : <button key={a.label} type="button" className={classes} role={a.isSelected === undefined ? undefined : 'menuitemradio'} aria-checked={a.isSelected === undefined ? undefined : !!a.isSelected} onClick={a.onPress}>{inner}</button>;
        })}
      </div>
    </div>
  );
}
