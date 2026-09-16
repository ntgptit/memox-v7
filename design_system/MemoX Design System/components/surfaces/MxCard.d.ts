import type { ReactNode, CSSProperties } from 'react';

/**
 * The primary content surface — elevated by default; flat/muted/primary variants.
 * @startingPoint section="Surfaces" subtitle="Rounded content surface with variants" viewport="360x180"
 */
export interface MxCardProps {
  /** Surface treatment. */
  variant?: 'flat' | 'muted' | 'primary' | 'primary-soft';
  /** Adds hover/press affordance. */
  interactive?: boolean;
  /** Padding override. */
  padding?: 'sm' | 'lg';
  node?: string;
  className?: string;
  children?: ReactNode;
  onClick?: () => void;
  style?: CSSProperties;
}

export function MxCard(props: MxCardProps): JSX.Element;
