import * as React from 'react';

export interface MxListTileProps {
  /** Already-localized. Two lines then ellipsis. */
  title: string;
  subtitle?: string;
  leading?: React.ReactNode;
  trailing?: React.ReactNode;
  /** Omitting it makes the row non-interactive without greying it out. */
  onClick?: () => void;
  /** false greys the row and removes it from the focus order — "never", where a null onClick says "not now". */
  isEnabled?: boolean;
  isSelected?: boolean;
}

export declare function MxListTile(props: MxListTileProps): React.JSX.Element;
