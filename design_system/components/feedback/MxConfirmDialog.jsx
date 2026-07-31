import React from 'react';
import { MxActionButton } from '../core/MxActionButton.jsx';

/**
 * Asks the user to confirm one action. It counts nothing and closes nothing —
 * the message arrives already pluralised, and the caller pops the route after the
 * work succeeded or failed.
 */
export function MxConfirmDialog({ title, message, confirmLabel, cancelLabel, onConfirm, onCancel, variant = 'normal', isSubmitting = false }) {
  const destructive = variant === 'destructive';
  return (
    <div className="mx-scrim" role="dialog" aria-modal="true" aria-label={title}>
      <div className="mx-dialog">
        <p className="mx-dialog__title">{title}</p>
        <p className="mx-dialog__message">{message}</p>
        <div className="mx-dialog__actions">
          <MxActionButton label={cancelLabel} variant="secondary" onClick={onCancel} isDisabled={isSubmitting} autoFocus={destructive} />
          <MxActionButton label={confirmLabel} variant={destructive ? 'destructive' : 'primary'} onClick={onConfirm} isLoading={isSubmitting} />
        </div>
      </div>
    </div>
  );
}
