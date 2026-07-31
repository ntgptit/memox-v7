import React from 'react';
import { MxIcon } from './MxIcon.jsx';

/**
 * The app's button. Takes no colour and no text style — appearance comes from
 * `variant` and the tokens, which is the whole point of having it instead of a
 * bare button. While `isLoading` it is disabled and shows a spinner but keeps
 * its size, so nothing beside it moves while the user waits.
 */
export function MxActionButton({
  label,
  onClick,
  variant = 'primary',
  isLoading = false,
  icon,
  isDisabled = false,
  isBlock = false,
  isCompact = false,
  autoFocus = false,
}) {
  const disabled = isDisabled || isLoading || !onClick;
  const classes = [
    'mx-btn',
    `mx-btn--${variant}`,
    isLoading ? 'mx-btn--loading' : '',
    isBlock ? 'mx-btn--block' : '',
    isCompact ? 'mx-btn--compact' : '',
  ].filter(Boolean).join(' ');

  return (
    <button type="button" className={classes} onClick={onClick} disabled={disabled} autoFocus={autoFocus} aria-busy={isLoading || undefined}>
      {icon ? <MxIcon name={icon} size="var(--icon-sm)" style={{ opacity: isLoading ? 0 : 1 }} /> : null}
      <span className="mx-btn__label">{label}</span>
      {isLoading ? <span className="mx-btn__spinner" /> : null}
    </button>
  );
}
