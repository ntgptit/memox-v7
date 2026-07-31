import React from 'react';
import { MxIcon } from './MxIcon.jsx';

/**
 * An action with no visible label. `semanticLabel` is required — that is the
 * entire reason this exists rather than a bare icon button: an icon-only control
 * with no label is a blank button to a screen reader. 48x48 is enforced by the
 * class, not by a prop.
 */
export function MxIconButton({ icon, semanticLabel, onClick, filled = false, tooltip, isDisabled = false }) {
  return (
    <button
      type="button"
      className="mx-iconbtn"
      onClick={onClick}
      disabled={isDisabled || !onClick}
      aria-label={semanticLabel}
      title={tooltip || semanticLabel}
    >
      <MxIcon name={icon} filled={filled} />
    </button>
  );
}
