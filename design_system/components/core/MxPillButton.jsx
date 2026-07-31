import React from 'react';
import { MxIcon } from './MxIcon.jsx';

/**
 * A selectable pill: the control for switching between a small, fixed set of
 * views of the same content. No checkmark — the group is always visible in full,
 * so the selected one is legible by contrast alone and a tick would shift the
 * label sideways on every change.
 */
export function MxPillButton({ label, isSelected, onClick, icon, semanticLabel }) {
  return (
    <button
      type="button"
      className="mx-pill"
      aria-pressed={isSelected}
      aria-label={semanticLabel}
      onClick={onClick}
      disabled={!onClick}
    >
      <span className="mx-pill__body">
        {icon ? <MxIcon name={icon} filled size="var(--icon-sm)" /> : null}
        {label}
      </span>
    </button>
  );
}
