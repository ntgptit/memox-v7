import type { ButtonHTMLAttributes } from 'react';

import type { MxIconName } from './MxIcon';

export interface MxPillButtonProps
  extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'onClick' | 'disabled' | 'children'> {
  /** Already-localized. */
  label: string;
  /** Whether this pill is the active one in its group. */
  isSelected: boolean;
  /**
   * `null` disables the pill. A pill with nothing to switch to should not be
   * rendered at all, so this is for the transient case — a control whose data has
   * not arrived — rather than for a permanent one.
   */
  onPressed?: (() => void) | null;
  /** Optional leading glyph. Decorative: the label is what is announced. */
  icon?: MxIconName;
  /**
   * Replaces `label` for assistive technology when the visible text is an
   * abbreviation — "A–Z" reads as two letters, not as "sort by name".
   */
  semanticLabel?: string;
}

export declare function MxPillButton(props: MxPillButtonProps): JSX.Element;
export default MxPillButton;
