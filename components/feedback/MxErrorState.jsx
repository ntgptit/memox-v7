import React from 'react';

import MxActionButton from '../core/MxActionButton.jsx';
import MxIcon from '../core/MxIcon.jsx';

/**
 * Shown when something failed and the user may be able to retry.
 *
 * Takes a `message` string, never an error object. Two reasons, and both bite
 * later: a shared component that knows the domain error type drags the error layer
 * into every UI test, and — more importantly — it would decide how a failure
 * reads, which is the screen's job. The screen picks localized copy for the failure
 * it got; this component only renders it.
 */
export function MxErrorState({
  title,
  message,
  retryLabel,
  onRetry,
  className = '',
  ...rest
}) {
  const hasRetry = retryLabel != null && onRetry != null;

  if ((retryLabel == null) !== (onRetry == null) && typeof console !== 'undefined') {
    console.warn(
      'MxErrorState: retry needs both a label and a callback. Half of the pair leaves an error the user can read and cannot act on.',
    );
  }

  return (
    <div
      className={`mx-state mx-state--error ${className}`.trim()}
      // `alert`, unlike the loading state's `status`: a failure is worth
      // interrupting for, because the user is waiting on something that is not
      // coming.
      role="alert"
      {...rest}
    >
      <MxIcon name="alert-circle" size="lg" className="mx-state__icon" />
      <h2 className="mx-state__title mx-type-title-medium">{title}</h2>
      <p className="mx-state__message mx-type-body-medium">{message}</p>
      {hasRetry ? (
        <div className="mx-state__action">
          <MxActionButton label={retryLabel} onPressed={onRetry} />
        </div>
      ) : null}
    </div>
  );
}

export default MxErrorState;
