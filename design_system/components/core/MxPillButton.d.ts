import * as React from 'react';

export interface MxPillButtonProps {
  /** Already-localized. */
  label: string;
  /** Whether this pill is the active one in its group. */
  isSelected: boolean;
  /** Omitting it disables the pill — for a control whose data has not arrived. */
  onClick?: () => void;
  /** Optional leading glyph, decorative only. */
  icon?: string;
  /** Replaces the label for assistive tech when the visible text is an abbreviation ("A–Z"). */
  semanticLabel?: string;
}

export declare function MxPillButton(props: MxPillButtonProps): React.JSX.Element;
