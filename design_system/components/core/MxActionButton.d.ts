import * as React from 'react';

/**
 * The one button in memox: primary, secondary (outlined) or destructive.
 *
 */
/**
 * The one button in memox: primary, secondary (outlined) or destructive.
 *
 * @startingPoint section="Core" subtitle="Primary, secondary and destructive actions" viewport="700x380"
 */
export interface MxActionButtonProps {
  /** Already-localized. The screen owns the copy; the button never reads ARB. */
  label: string;
  /** Omitting it disables the button. */
  onClick?: () => void;
  /** primary = the one action a screen wants; secondary = everything else; destructive = deletes or discards. */
  variant?: 'primary' | 'secondary' | 'destructive';
  /** Disabled, spinner shown, size unchanged. */
  isLoading?: boolean;
  /** Material Icons ligature name for a leading glyph, rendered at --icon-sm. */
  icon?: string;
  isDisabled?: boolean;
  /** Full-width, as used for "Study 15 cards due today" and "End session". */
  isBlock?: boolean;
  /** Compact padding (12px a side) for the <360px case. */
  isCompact?: boolean;
  autoFocus?: boolean;
}

export declare function MxActionButton(props: MxActionButtonProps): React.JSX.Element;
