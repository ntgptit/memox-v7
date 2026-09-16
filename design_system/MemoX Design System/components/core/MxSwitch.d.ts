export interface MxSwitchProps {
  checked?: boolean;
  disabled?: boolean;
  onChange?: (next: boolean) => void;
  node?: string;
}

/** Binary on/off toggle with a growing thumb. Base class `switch`. */
export function MxSwitch(props: MxSwitchProps): JSX.Element;
