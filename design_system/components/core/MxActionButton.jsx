import React from 'react';
import { MxIcon } from './MxIcon.jsx';

/**
 * The app's button. Takes no colour and no text style — appearance comes from
 * `variant` and the tokens, which is the whole point of having it instead of a
 * bare button. While `isLoading` it is disabled and shows a spinner but keeps
 * its size, so nothing beside it moves while the user waits.
 *
 * `shouldKeepLabelWhileLoading` opts out of that trade: the label stays painted
 * and the spinner sits beside it. It costs the fixed width, so use it only
 * where the width is decided from outside (`isBlock`, or a flex row), and use
 * it wherever the wait has a name the user has to read — a spinner alone says
 * "wait" to a screen reader and nothing at all to everyone else.
 */
export function MxActionButton({
  label,
  onClick,
  variant = 'primary',
  isLoading = false,
  shouldKeepLabelWhileLoading = false,
  icon,
  isDisabled = false,
  isBlock = false,
  isCompact = false,
  autoFocus = false,
}) {
  const disabled = isDisabled || isLoading || !onClick;
  const showsLabelledSpinner = isLoading && shouldKeepLabelWhileLoading;
  const classes = [
    'mx-btn',
    `mx-btn--${variant}`,
    isLoading ? 'mx-btn--loading' : '',
    showsLabelledSpinner ? 'mx-btn--loading-labelled' : '',
    isBlock ? 'mx-btn--block' : '',
    isCompact ? 'mx-btn--compact' : '',
  ].filter(Boolean).join(' ');

  return (
    <button type="button" className={classes} onClick={onClick} disabled={disabled} autoFocus={autoFocus} aria-busy={isLoading || undefined}>
      {/* The spinner takes the leading slot the icon would have used, so the
          button reads as one row rather than a glyph and a spinner competing
          for the same corner. */}
      {showsLabelledSpinner ? <span className="mx-btn__spinner" /> : null}
      {icon && !showsLabelledSpinner ? <MxIcon name={icon} size="var(--icon-sm)" style={{ opacity: isLoading ? 0 : 1 }} /> : null}
      <span className="mx-btn__label">{label}</span>
      {isLoading && !showsLabelledSpinner ? <span className="mx-btn__spinner" /> : null}
    </button>
  );
}
