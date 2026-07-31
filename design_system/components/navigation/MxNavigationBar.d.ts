import * as React from 'react';

export interface MxNavigationDestination {
  /** Material Icons ligature name, outlined when idle. */
  icon: string;
  /** Filled twin shown when selected. Defaults to the same name, filled. */
  selectedIcon?: string;
  /** Already-localized, and always visible. */
  label: string;
}

export interface MxNavigationBarProps {
  /** Out-of-range values are the caller's bug and are not silently clamped. */
  selectedIndex: number;
  onDestinationSelected: (index: number) => void;
  /** At least two: a one-destination bar has nothing to navigate between. */
  destinations: MxNavigationDestination[];
}

export declare function MxNavigationBar(props: MxNavigationBarProps): React.JSX.Element;
