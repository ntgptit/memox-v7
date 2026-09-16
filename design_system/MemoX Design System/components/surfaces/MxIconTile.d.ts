export interface MxIconTileProps {
  /** Material Symbols Rounded ligature name. */
  icon: string;
  /** Color tone (defaults to soft primary). */
  tone?: 'accent' | 'success' | 'warning' | 'error';
  size?: 'lg';
  /** Solid primary fill instead of soft tint. */
  solid?: boolean;
  node?: string;
  className?: string;
}

/** A rounded, tinted tile that frames a single icon — used as deck/list leading art. Base class `icon-tile`. */
export function MxIconTile(props: MxIconTileProps): JSX.Element;
