import React from 'react';

import MxActionButton from '../core/MxActionButton.jsx';

/**
 * Asks the user to confirm one action.
 *
 * It counts nothing. A caller deleting a deck knows it is taking four sub-decks
 * and eleven cards with it; that sentence is built there, already localized and
 * already pluralised, and arrives here as `message`. A shared dialog that knew
 * about decks could not be used for anything else, and one that did its own
 * pluralisation would do it in one language.
 *
 * It does not close itself. The caller dismisses it in its callback, after the work
 * either succeeded or failed. A dialog that dismissed on press would unmount
 * `isSubmitting` before it could ever be shown, and the user would see the screen
 * behind it while the delete was still running.
 */
export function MxConfirmDialog({
  title,
  message,
  confirmLabel,
  cancelLabel,
  onConfirm,
  onCancel,
  variant = 'normal',
  isSubmitting = false,
  className = '',
  ...rest
}) {
  const isDestructive = variant === 'destructive';
  const titleId = React.useId();
  const messageId = React.useId();

  return (
    <div
      className="mx-scrim"
      // The barrier dismisses, and only when nothing is in flight. Cancelling a
      // delete that has already been sent does not un-send it.
      onClick={isSubmitting ? undefined : onCancel}
    >
      <div
        className={`mx-dialog ${className}`.trim()}
        role="alertdialog"
        aria-modal="true"
        aria-labelledby={titleId}
        aria-describedby={messageId}
        // The dialog is inside the barrier, so a press on the panel would bubble
        // up to it and dismiss the thing the user just aimed at.
        onClick={(event) => event.stopPropagation()}
        onKeyDown={(event) => {
          if (event.key === 'Escape' && !isSubmitting) onCancel();
        }}
        {...rest}
      >
        <h2 id={titleId} className="mx-dialog__title mx-type-title-medium">
          {title}
        </h2>
        {/* Scrollable because the alternative is silent truncation, not an error.
            At a 3× text scale on a 320-wide screen a translated message clips
            mid-word: no exception, nothing a passing test would notice — and the
            user confirms a delete having read half the sentence describing it. */}
        <div id={messageId} className="mx-dialog__content mx-type-body-medium">
          {message}
        </div>
        <div className="mx-dialog__actions">
          <MxActionButton
            label={cancelLabel}
            onPressed={isSubmitting ? null : onCancel}
            variant="secondary"
            // Focus starts on cancel for a destructive dialog, so a stray Enter
            // does not delete anything. On a normal dialog neither action is
            // autofocused: pre-selecting "confirm" makes the keyboard path skip
            // the question the dialog exists to ask.
            shouldAutofocus={isDestructive}
          />
          <MxActionButton
            label={confirmLabel}
            onPressed={isSubmitting ? null : onConfirm}
            variant={isDestructive ? 'destructive' : 'primary'}
            isLoading={isSubmitting}
          />
        </div>
      </div>
    </div>
  );
}

export default MxConfirmDialog;
