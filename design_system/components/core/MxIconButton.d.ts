import * as React from 'react';

export interface MxIconButtonProps {
  /** Material Icons ligature name. */
  icon: string;
  /** Already-localized, and REQUIRED. What the action does, not what the glyph looks like. */
  semanticLabel: string;
  /** Omitting it disables the button. */
  onClick?: () => void;
  filled?: boolean;
  /** Only when the hover text should read differently from semanticLabel. */
  tooltip?: string;
  isDisabled?: boolean;
  /** standard = the bar's own ink; warning = a state the user set and can undo, such as the card editor's raised flag. Never the only signal — change the glyph too. */
  tone?: 'standard' | 'warning';
}

export declare function MxIconButton(props: MxIconButtonProps): React.JSX.Element;
