import * as React from 'react';

export interface MxActionSheetAction {
  /** Already-localized. */
  label: string;
  onPress: () => void;
  icon?: string;
  variant?: 'normal' | 'destructive';
  /** false greys the row and blocks the callback — the row stays visible on purpose. */
  isEnabled?: boolean;
}

export interface MxActionSheetProps {
  actions: MxActionSheetAction[];
  /** Already-localized. */
  title?: string;
  onDismiss?: () => void;
}

export declare function MxActionSheet(props: MxActionSheetProps): React.JSX.Element;
