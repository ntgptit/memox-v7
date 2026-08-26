import React from 'react';
import { MxIcon } from './MxIcon.jsx';

/**
 * An action with no visible label. `semanticLabel` is required — that is the
 * entire reason this exists rather than a bare icon button: an icon-only control
 * with no label is a blank button to a screen reader. 48x48 is enforced by the
 * class, not by a prop.
 *
 * `tone` is an enum rather than a colour prop: a colour prop lets any caller
 * paint any glyph any shade, which is how a kit ends up with four oranges. It
 * is also never the only signal — the caller changes the glyph with the state
 * too, and the label says which way the next tap goes.
 */
export function MxIconButton({ icon, semanticLabel, onClick, filled = false, tooltip, isDisabled = false, tone = 'standard' }) {
  return (
    <button
      type="button"
      className={['mx-iconbtn', tone === 'standard' ? '' : `mx-iconbtn--${tone}`].filter(Boolean).join(' ')}
      onClick={onClick}
      disabled={isDisabled || !onClick}
      aria-label={semanticLabel}
      title={tooltip || semanticLabel}
    >
      <MxIcon name={icon} filled={filled} />
    </button>
  );
}
