import React from 'react';

/**
 * The loading state, centred in whatever space it is given.
 *
 * Takes an already-localized `semanticsLabel` because a bare spinner is invisible
 * to a screen reader — it announces nothing at all, so the user is told neither
 * that something is happening nor when it stops.
 *
 * A spinner rather than a shimmer skeleton, on purpose. Skeletons exist to mask
 * network latency; these reads are local and finish in single-digit milliseconds,
 * so a skeleton would render a fake layout for less than a frame and then replace
 * it — motion that says "slow" about something that is not.
 */
export function MxLoadingState({ semanticsLabel, className = '', ...rest }) {
  return (
    <div
      className={`mx-loading ${className}`.trim()}
      // `status`, not `alert`: this is a state change worth announcing once the
      // reader reaches a pause, not something to interrupt for.
      role="status"
      aria-live="polite"
      {...rest}
    >
      <svg className="mx-spinner" viewBox="0 0 24 24" aria-hidden="true">
        {/* Explicitly no track behind the arc. Material draws a faint one in newer
            versions; on a card that reads as a second ring nobody asked for. */}
        <circle className="mx-spinner__arc" cx="12" cy="12" r="9" />
      </svg>
      <span className="mx-visually-hidden">{semanticsLabel}</span>
    </div>
  );
}

export default MxLoadingState;
