import type { HTMLAttributes } from 'react';

/**
 * Whether the confirmed action destroys something.
 *
 * A union rather than an `isDestructive` flag beside a colour: a flag and a colour
 * can be passed independently, and a caller that sets one without the other
 * produces a dialog that looks safe and is not.
 */
export type MxConfirmDialogVariant = 'normal' | 'destructive';

export interface MxConfirmDialogProps extends Omit<HTMLAttributes<HTMLDivElement>, 'title'> {
  /** Already-localized, and complete — the dialog counts nothing itself. */
  title: string;
  message: string;
  confirmLabel: string;
  cancelLabel: string;
  onConfirm: () => void;
  /** Also fired by Escape and by the barrier, unless `isSubmitting`. */
  onCancel: () => void;
  variant?: MxConfirmDialogVariant;
  /**
   * While true both actions are inert. Confirming a delete twice sends two
   * deletes, and the second fails against data the first already removed — which
   * surfaces to the user as an error for an action that worked.
   */
  isSubmitting?: boolean;
}

export declare function MxConfirmDialog(props: MxConfirmDialogProps): JSX.Element;
export default MxConfirmDialog;
