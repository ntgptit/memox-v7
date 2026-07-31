import type { HTMLAttributes } from 'react';

import type { MxIconName } from '../core/MxIcon';

export interface MxNavigationDestination {
  /** Already-localized. Always visible — never hidden when unselected. */
  label: string;
  icon: MxIconName;
  /** Optional filled or emphasised variant for the selected state. */
  selectedIcon?: MxIconName;
  key?: string;
}

export interface MxNavigationBarProps extends HTMLAttributes<HTMLElement> {
  /**
   * Which destination is current. Out-of-range values are the caller's bug and are
   * not silently clamped — a bar that shows tab 0 when the router says 3 is a
   * navigation bug wearing a working UI.
   */
  selectedIndex: number;
  onDestinationSelected: (index: number) => void;
  /** Already-localized, and at least two: a one-destination bar has nothing to navigate between. */
  destinations: MxNavigationDestination[];
  semanticLabel?: string;
}

export declare function MxNavigationBar(props: MxNavigationBarProps): JSX.Element;
export default MxNavigationBar;
