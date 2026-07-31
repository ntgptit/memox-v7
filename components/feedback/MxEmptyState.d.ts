import type { HTMLAttributes } from 'react';

import type { MxIconName } from '../core/MxIcon';

export interface MxEmptyStateProps extends HTMLAttributes<HTMLDivElement> {
  /** Already-localized. The screen owns the copy. */
  title: string;
  message?: string;
  /** Supply with `onAction` or not at all. */
  actionLabel?: string;
  onAction?: () => void;
  /** Defaults to `check-circle` — the shape of "nothing left to do". */
  icon?: MxIconName;
}

export declare function MxEmptyState(props: MxEmptyStateProps): JSX.Element;
export default MxEmptyState;
