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
  /** Drops the label to `--text-label-md`, for a link sharing a row with a
   * heading set at that rung. Only the type moves — never the 48 target. */
  isCompact?: boolean;
  /** What a screen reader announces instead of the painted words, for a link
   * whose label is a VALUE rather than an action. Must CONTAIN the painted
   * label (WCAG 2.5.3) — a voice-control user says what they can see. */
  semanticLabel?: string;
}

export declare function MxTextButton(props: MxTextButtonProps): React.JSX.Element;
