import React from 'react';

import MxIcon from './MxIcon.jsx';

/**
 * An action with no visible label.
 *
 * `semanticLabel` is REQUIRED, and that is the entire reason this component exists
 * rather than a `<button>` with an icon in it. An icon-only control with no label
 * is a blank button to a screen reader — the user is told there is something
 * pressable and nothing about what it does. Making the label optional means it
 * gets omitted, because omitting it changes nothing anyone can see.
 *
 * Size comes from the stylesheet and the 48x48 minimum with it; neither is a prop,
 * so no screen can shrink a target below what a thumb can hit.
 */
export function MxIconButton({
  icon,
  semanticLabel,
  onPressed,
  tooltip,
  type = 'button',
  className = '',
  ...rest
}) {
  return (
    <button
      type={type}
      className={`mx-icon-button ${className}`.trim()}
      // The visible hover/long-press text falls back to the label, so the two
      // cannot drift apart unless a caller deliberately separates them.
      title={tooltip ?? semanticLabel}
      aria-label={semanticLabel}
      disabled={onPressed == null}
      onClick={onPressed ?? undefined}
      {...rest}
    >
      {/* The name is on the button, so the icon stays decorative. Labelling both
          has the reader announce it twice. */}
      <MxIcon name={icon} size="md" />
    </button>
  );
}

export default MxIconButton;
