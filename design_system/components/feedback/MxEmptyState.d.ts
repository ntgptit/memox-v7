import * as React from 'react';

export interface MxEmptyStateProps {
  /** Already-localized. */
  title: string;
  message?: string;
  /** Defaults to check_circle_outline — "you are finished". Use folder_outlined for "nothing created yet". */
  icon?: string;
  /** An empty state has an action or it does not: pass both or neither. */
  actionLabel?: string;
  onAction?: () => void;
}

export declare function MxEmptyState(props: MxEmptyStateProps): React.JSX.Element;
