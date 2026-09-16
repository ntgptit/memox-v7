import type { ReactNode, ChangeEvent } from 'react';

export interface MxSearchDockProps {
  placeholder?: string;
  value?: string;
  onChange?: (e: ChangeEvent<HTMLInputElement>) => void;
  /** Focused ring treatment. */
  focused?: boolean;
  /** Flat (muted) instead of elevated. */
  flat?: boolean;
  /** Trailing slot (filter button, etc.). */
  trailing?: ReactNode;
  node?: string;
}

/** Rounded search dock with a leading search glyph. Base class `search-dock`. */
export function MxSearchDock(props: MxSearchDockProps): JSX.Element;
