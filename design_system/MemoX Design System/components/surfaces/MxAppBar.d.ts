import type { ReactNode } from 'react';

export interface MxAppBarProps {
  /** Title text or node. */
  title?: ReactNode;
  /** Small label above the large title. */
  eyebrow?: ReactNode;
  /** Render the tall Material-3 large top app bar. */
  large?: boolean;
  /** Leading slot (back button, avatar…). */
  leading?: ReactNode;
  /** Trailing slot (icon buttons). */
  trailing?: ReactNode;
  node?: string;
  className?: string;
}

/** Top app bar — compact by default, hero variant via `large`. Base class `appbar` / `appbar-lg`. */
export function MxAppBar(props: MxAppBarProps): JSX.Element;
