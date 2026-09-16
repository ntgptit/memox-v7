import type { ReactNode } from 'react';

export interface MxBadgeProps {
  children?: ReactNode;
  tone?: 'success' | 'warning' | 'error';
  /** Soft tinted variant instead of solid. */
  soft?: boolean;
  /** Render a bare status dot (no content). */
  dot?: boolean;
  node?: string;
}

/** Small count or status badge; solid or soft, with an optional dot form. Base class `badge`. */
export function MxBadge(props: MxBadgeProps): JSX.Element;
