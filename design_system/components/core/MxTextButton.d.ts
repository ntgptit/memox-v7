import * as React from 'react';

export interface MxTextButtonProps {
  /** Already-localized. The screen owns the copy; the button never builds a sentence. */
  label: string;
  /** Omitting it disables the button. */
  onClick?: () => void;
  /** Material Icons ligature name, drawn before the label. */
  icon?: string;
  /** Material Icons ligature name, drawn after the label — e.g. `expand_more`. */
  trailingIcon?: string;
  isDisabled?: boolean;
  /** Danger as a LABEL, not as a fill: the text goes `--color-danger`. */
  isDestructive?: boolean;
}

export declare function MxTextButton(props: MxTextButtonProps): React.JSX.Element;
