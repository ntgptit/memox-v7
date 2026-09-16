export interface MxFabProps {
  /** Material Symbols Rounded ligature name. */
  icon?: string;
  /** Extended-FAB label; omit for a round FAB. */
  label?: string;
  variant?: 'accent';
  /** Force the round (icon-only) shape. */
  round?: boolean;
  node?: string;
  onClick?: () => void;
}

/** Floating action button — extended (icon+label) or round. Base class `fab`. */
export function MxFab(props: MxFabProps): JSX.Element;
