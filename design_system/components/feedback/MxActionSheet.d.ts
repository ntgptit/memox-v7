import * as React from 'react';

export interface MxActionSheetAction {
  /** Already-localized. */
  label: string;
  onPress: () => void;
  icon?: string;
  variant?: 'normal' | 'destructive';
  /** false greys the row and blocks the callback — the row stays visible on purpose. */
  isEnabled?: boolean;
  /** Marks the row the app is already in, for a sheet that CHOOSES rather than
   * acts. Draws a trailing check and sets aria-checked. Leave undefined on a
   * sheet of plain actions — there is no current state for it to mark. */
  isSelected?: boolean;
}

export interface MxActionSheetProps {
  actions: MxActionSheetAction[];
  /** Already-localized. */
  title?: string;
  onDismiss?: () => void;
}

export declare function MxActionSheet(props: MxActionSheetProps): React.JSX.Element;
