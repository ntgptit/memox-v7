import React from 'react';

/**
 * A spinner rather than a shimmer skeleton, on purpose: these reads are local
 * SQLite and finish in single-digit milliseconds, so a skeleton would render a
 * fake layout for less than a frame.
 */
export function MxLoadingState({ semanticsLabel }) {
  return (
    <div className="mx-state" role="status" aria-label={semanticsLabel}>
      <span className="mx-spinner" />
    </div>
  );
}
