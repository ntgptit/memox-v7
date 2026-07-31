import React from 'react';
import { MxIcon } from '../core/MxIcon.jsx';
import { MxActionButton } from '../core/MxActionButton.jsx';

/** Shown when something failed and the user may be able to retry. */
export function MxErrorState({ title, message, retryLabel, onRetry }) {
  return (
    <div className="mx-state">
      <MxIcon name="error_outline" size="var(--icon-lg)" color="var(--color-danger)" className="mx-state__icon" />
      <div className="mx-state__stack">
        <p className="mx-state__title">{title}</p>
        <p className="mx-state__message">{message}</p>
      </div>
      {retryLabel && onRetry ? <MxActionButton label={retryLabel} variant="secondary" onClick={onRetry} /> : null}
    </div>
  );
}
