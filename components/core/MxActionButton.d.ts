import type { ButtonHTMLAttributes } from 'react';

import type { MxIconName } from './MxIcon';

/**
 * How much weight a button carries on its screen.
 *
 * A union, not a colour prop. `destructive` is carried here rather than by an
 * `isDestructive` flag beside a colour: a flag and a colour can be passed
 * independently, and the mismatch is invisible in review.
 */
export type MxActionButtonVariant = 'primary' | 'secondary' | 'destructive';

export interface MxActionButtonProps
  extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'onClick' | 'disabled' | 'children'> {
  /** Already-localized. The screen owns the copy; the button never reads a catalogue. */
  label: string;
  /** `null` or omitted disables the button. */
  onPressed?: (() => void) | null;
  variant?: MxActionButtonVariant;
  /** Disables the button and shows a spinner — at the width it already had. */
  isLoading?: boolean;
  /** Optional leading glyph. Decorative: the label is what is announced. */
  icon?: MxIconName;
  /** Whether this button takes focus when its dialog or route opens. */
  shouldAutofocus?: boolean;
}

export declare function MxActionButton(props: MxActionButtonProps): JSX.Element;
export default MxActionButton;
