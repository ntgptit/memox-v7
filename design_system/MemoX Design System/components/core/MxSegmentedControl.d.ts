export interface MxSegment {
  value: string;
  label: string;
  /** Material Symbols Rounded ligature name. */
  icon?: string;
}

export interface MxSegmentedControlProps {
  /** Segment list — strings or {value,label,icon}. */
  segments: Array<string | MxSegment>;
  value?: string;
  onChange?: (value: string) => void;
  /** Stretch segments to fill width. */
  block?: boolean;
  node?: string;
}

/** Segmented control for 2–3 mutually-exclusive views. Base class `segmented`. */
export function MxSegmentedControl(props: MxSegmentedControlProps): JSX.Element;
