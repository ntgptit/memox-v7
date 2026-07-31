import type { HTMLAttributes } from 'react';

import type { MxIconName } from '../core/MxIcon';

/** Whether an action in a sheet destroys something. */
export type MxActionSheetActionVariant = 'normal' | 'destructive';

/** One row of an `MxActionSheet`. */
export interface MxActionSheetAction {
  /** Already-localized. */
  label: string;
  onPressed: () => void;
  icon?: MxIconName;
  /**
   * Carried by the variant so the sheet can style **and** announce it; colour
   * alone would say nothing to a screen reader and nothing to a colour-blind user.
   */
  variant?: MxActionSheetActionVariant;
  /**
   * `false` greys the row and blocks the callback. The row stays visible on
   * purpose: hiding an unavailable action makes the menu change shape between
   * visits, and the user cannot learn where anything is.
   */
  isEnabled?: boolean;
  /** Stable identity when two rows can share a label. */
  key?: string;
}

export interface MxActionSheetProps extends HTMLAttributes<HTMLDivElement> {
  actions: MxActionSheetAction[];
  /** Already-localized. */
  title?: string;
  /** Fired by Escape and by the barrier. The sheet never closes itself. */
  onDismiss?: () => void;
}

export declare function MxActionSheet(props: MxActionSheetProps): JSX.Element;
export default MxActionSheet;
