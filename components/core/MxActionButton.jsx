import React from 'react';

import MxIcon from './MxIcon.jsx';

/**
 * The app's button.
 *
 * Takes no colour and no text style. Appearance comes from `variant` and the
 * stylesheet; that is the whole point of having this component instead of a
 * `<button>` with classes at every call site. The moment a caller can pass a
 * colour the design system stops being enforceable — every screen is free to
 * invent a shade, and no reviewer can tell an intentional variant from a typo.
 *
 * `onPressed` is `null`/omitted to disable, mirroring the Dart widget rather than
 * React's `disabled` prop. One source of truth for "can this be pressed" is what
 * keeps a caller from shipping a live handler on a disabled button.
 */
export function MxActionButton({
  label,
  onPressed,
  variant = 'primary',
  isLoading = false,
  icon,
  shouldAutofocus = false,
  type = 'button',
  className = '',
  ...rest
}) {
  // Disabled while loading: without this a second press queues a second submit,
  // which is the double-submit bug in its most common form.
  const isDisabled = onPressed == null || isLoading;

  const content = (
    <span className="mx-button__content">
      {icon ? <MxIcon name={icon} size="sm" className="mx-button__icon" /> : null}
      <span className="mx-button__label">{label}</span>
    </span>
  );

  return (
    <button
      type={type}
      className={[
        'mx-button',
        `mx-button--${variant}`,
        isLoading ? 'mx-button--loading' : '',
        'mx-focus-ring',
        className,
      ]
        .filter(Boolean)
        .join(' ')}
      disabled={isDisabled}
      autoFocus={shouldAutofocus}
      // The name is on the button itself rather than left to the label span,
      // which the loading state hides. Without it a submitting button announces
      // as "button, disabled" with no name at all — the user is told something is
      // unavailable and never told what.
      aria-label={label}
      aria-busy={isLoading || undefined}
      onClick={isDisabled ? undefined : onPressed}
      {...rest}
    >
      {content}
      {isLoading ? (
        // The label stays laid out and merely invisible, so the button keeps the
        // width it had before the press. Swapping the child for a spinner would
        // resize it, and everything beside it would move exactly when the user is
        // waiting to see what happened.
        <span className="mx-button__spinner">
          <svg className="mx-spinner mx-spinner--sm" viewBox="0 0 24 24" aria-hidden="true">
            <circle className="mx-spinner__arc" cx="12" cy="12" r="9" />
          </svg>
        </span>
      ) : null}
    </button>
  );
}

export default MxActionButton;
