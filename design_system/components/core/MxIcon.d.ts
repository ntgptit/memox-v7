import * as React from 'react';

export interface MxIconProps {
  /** Material Icons ligature name, e.g. "folder", "more_vert", "local_fire_department". */
  name: string;
  /** Filled variant (Icons.folder) rather than outlined (Icons.folder_outlined). */
  filled?: boolean;
  /** Defaults to --icon-md (24px). Use --icon-sm inline with text, --icon-lg in a state. */
  size?: number | string;
  color?: string;
  className?: string;
  style?: React.CSSProperties;
}

export declare function MxIcon(props: MxIconProps): React.JSX.Element;
