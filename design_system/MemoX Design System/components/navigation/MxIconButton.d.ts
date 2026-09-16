export interface MxIconButtonProps {
  /** Material Symbols Rounded ligature name. */
  icon: string;
  variant?: 'filled' | 'primary';
  size?: 'sm';
  node?: string;
  className?: string;
  onClick?: () => void;
  ariaLabel?: string;
}

/** Icon-only round button for app-bar & toolbar actions. Base class `icon-btn`. */
export function MxIconButton(props: MxIconButtonProps): JSX.Element;
