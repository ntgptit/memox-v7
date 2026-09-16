import type { ReactNode } from 'react';

/**
 * Primary text button with four emphasis levels.
 * @startingPoint section="Core" subtitle="Button — primary / secondary / outline / ghost" viewport="320x120"
 */
export interface MxButtonProps {
  /** Emphasis. `contrast` is a white pill for use ON a colored/primary card. */
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'contrast';
  size?: 'sm' | 'lg';
  /** Leading icon (Material Symbols name). */
  icon?: string;
  /** Trailing icon (Material Symbols name). */
  trailingIcon?: string;
  /** Full-width. */
  block?: boolean;
  /** Destructive color (composes with variant). */
  danger?: boolean;
  disabled?: boolean;
  node?: string;
  className?: string;
  children?: ReactNode;
  onClick?: () => void;
  type?: 'button' | 'submit' | 'reset';
}

export function MxButton(props: MxButtonProps): JSX.Element;
