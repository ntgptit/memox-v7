export interface MxBottomNavItem {
  id: string;
  label: string;
  /** Material Symbols Rounded ligature name. */
  icon: string;
}

export interface MxBottomNavProps {
  items: MxBottomNavItem[];
  /** Active item id. */
  value?: string;
  onChange?: (id: string) => void;
  node?: string;
}

/** Fixed bottom navigation with an active pill indicator. Base class `bottom-nav`. */
export function MxBottomNav(props: MxBottomNavProps): JSX.Element;
