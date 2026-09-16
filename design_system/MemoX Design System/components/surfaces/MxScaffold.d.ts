import type { ReactNode, CSSProperties } from 'react';

/**
 * The root phone-screen frame for every MemoX screen.
 * @startingPoint section="Shell" subtitle="App scaffold with app bar, body, nav & FAB" viewport="390x844"
 */
export interface MxScaffoldProps {
  /** Top app bar element (usually <MxAppBar/>). */
  appBar?: ReactNode;
  /** Bottom navigation element (usually <MxBottomNav/>). */
  bottomNav?: ReactNode;
  /** Floating action button, parked above the bottom nav. */
  fab?: ReactNode;
  /** Scrollable screen content. */
  children?: ReactNode;
  /** Remove the body's horizontal padding (for full-bleed content). */
  flush?: boolean;
  /** Stable semantic id, e.g. "dashboard/screen". */
  node?: string;
  className?: string;
  style?: CSSProperties;
}

export function MxScaffold(props: MxScaffoldProps): JSX.Element;
