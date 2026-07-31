import * as React from 'react';

export interface MxConfirmDialogProps {
  /** Already-localized, and complete — the dialog counts nothing itself. */
  title: string;
  message: string;
  confirmLabel: string;
  cancelLabel: string;
  onConfirm: () => void;
  onCancel: () => void;
  /** destructive styles the confirm AND moves initial focus to cancel. */
  variant?: 'normal' | 'destructive';
  /** While true both actions are inert — confirming a delete twice is the classic double-submit. */
  isSubmitting?: boolean;
}

export declare function MxConfirmDialog(props: MxConfirmDialogProps): React.JSX.Element;
