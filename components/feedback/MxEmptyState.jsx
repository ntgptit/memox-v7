import React from 'react';

import MxActionButton from '../core/MxActionButton.jsx';
import MxIcon from '../core/MxIcon.jsx';

/**
 * Shown when there is nothing to display and that is fine.
 *
 * Deliberately distinct from `MxErrorState`: "you have finished everything due
 * today" is good news, and rendering it in error styling tells the user something
 * is broken when nothing is (BR-29).
 *
 * An action is a label AND a callback, or neither. With only a label the button
 * renders and does nothing; with only a callback it never renders at all — and
 * either way the screen looks deliberately action-free and no test fails.
 */
export function MxEmptyState({
  title,
  message,
  actionLabel,
  onAction,
  icon = 'check-circle',
  className = '',
  ...rest
}) {
  const hasAction = actionLabel != null && onAction != null;

  if ((actionLabel == null) !== (onAction == null) && typeof console !== 'undefined') {
    console.warn(
      'MxEmptyState: an empty state has an action or it does not. Half of the pair is dropped silently.',
    );
  }

  return (
    <div className={`mx-state ${className}`.trim()} {...rest}>
      {/* Decorative, despite standing alone. The title directly below it says the
          same thing in words, so naming the glyph as well would have the reader
          announce the state twice — and the second announcement would be the
          weaker one, since a shape can only ever approximate the sentence. */}
      <MxIcon name={icon} size="lg" className="mx-state__icon" />
      <h2 className="mx-state__title mx-type-title-medium">{title}</h2>
      {message ? <p className="mx-state__message mx-type-body-medium">{message}</p> : null}
      {hasAction ? (
        <div className="mx-state__action">
          {/* Primary, not secondary. This screen has one thing to do and nothing
              to weigh it against; an outlined button on an otherwise empty screen
              reads as optional. */}
          <MxActionButton label={actionLabel} onPressed={onAction} />
        </div>
      ) : null}
    </div>
  );
}

export default MxEmptyState;
