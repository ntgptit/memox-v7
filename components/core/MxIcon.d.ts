import type { SVGProps } from 'react';

/** The three steps of `AppIconSize`. Never a free number. */
export type MxIconSize = 'sm' | 'md' | 'lg';

export type MxIconName =
  | 'check'
  | 'check-circle'
  | 'alert-circle'
  | 'alert-triangle'
  | 'info'
  | 'chevron-right'
  | 'chevron-left'
  | 'chevron-down'
  | 'arrow-left'
  | 'arrow-right'
  | 'search'
  | 'close'
  | 'plus'
  | 'minus'
  | 'menu'
  | 'more-vertical'
  | 'edit'
  | 'trash'
  | 'refresh'
  | 'inbox'
  | 'folder'
  | 'layers'
  | 'clock'
  | 'calendar'
  | 'star'
  | 'filter'
  | 'sort'
  | 'settings';

export interface MxIconProps extends Omit<SVGProps<SVGSVGElement>, 'name' | 'ref'> {
  name: MxIconName;
  /** `sm` inline with text, `md` for actions, `lg` for an empty or error state. */
  size?: MxIconSize;
  /**
   * Already-localized. Omit — the default — for a glyph that sits beside its own
   * label; the icon is then hidden from assistive technology instead of being
   * announced twice.
   */
  label?: string;
}

export declare const MX_ICON_NAMES: MxIconName[];
export declare function MxIcon(props: MxIconProps): JSX.Element | null;
export default MxIcon;
