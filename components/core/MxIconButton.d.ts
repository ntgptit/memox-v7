import type { ButtonHTMLAttributes } from 'react';

import type { MxIconName } from './MxIcon';

export interface MxIconButtonProps
  extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'onClick' | 'disabled' | 'title' | 'children'> {
  icon: MxIconName;
  /**
   * Already-localized, and required. What the action does, not what the glyph
   * looks like: "Delete deck", never "bin".
   */
  semanticLabel: string;
  /** `null` or omitted disables the button. */
  onPressed?: (() => void) | null;
  /**
   * Already-localized. Only when the visible hover text should read differently
   * from `semanticLabel`; otherwise the label serves both and the two cannot
   * drift apart.
   */
  tooltip?: string;
}

export declare function MxIconButton(props: MxIconButtonProps): JSX.Element;
export default MxIconButton;
