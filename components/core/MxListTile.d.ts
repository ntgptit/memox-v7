import type { HTMLAttributes, ReactNode } from 'react';

export interface MxListTileProps extends Omit<HTMLAttributes<HTMLElement>, 'onClick' | 'title'> {
  /** Already-localized, or the user's own text. Two lines, then ellipsis. */
  title: string;
  /** Already-localized. Two lines, then ellipsis. */
  subtitle?: string;
  leading?: ReactNode;
  trailing?: ReactNode;
  /**
   * `null` makes the row non-interactive without greying it out — a heading row,
   * or a row whose action has not loaded yet.
   */
  onTap?: (() => void) | null;
  /**
   * `false` greys the row and removes it from the focus order. Distinct from a
   * null `onTap`: one says "not now", the other says "never".
   */
  isEnabled?: boolean;
  isSelected?: boolean;
}

export declare function MxListTile(props: MxListTileProps): JSX.Element;
export default MxListTile;
