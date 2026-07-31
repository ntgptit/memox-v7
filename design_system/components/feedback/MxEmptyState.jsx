import React from 'react';
import { MxIcon } from '../core/MxIcon.jsx';
import { MxActionButton } from '../core/MxActionButton.jsx';

/**
 * Shown when there is nothing to display and that is fine. Deliberately distinct
 * from MxErrorState: "you have finished everything due today" is good news, and
 * rendering it in error styling tells the user something is broken (BR-29).
 */
export function MxEmptyState({ title, message, icon = 'check_circle_outline', actionLabel, onAction }) {
  return (
    <div className="mx-state">
      <MxIcon name={icon} size="var(--icon-lg)" color="var(--color-primary)" className="mx-state__icon" />
      <div className="mx-state__stack">
        <p className="mx-state__title">{title}</p>
        {message ? <p className="mx-state__message">{message}</p> : null}
      </div>
      {actionLabel && onAction ? <MxActionButton label={actionLabel} onClick={onAction} /> : null}
    </div>
  );
}
