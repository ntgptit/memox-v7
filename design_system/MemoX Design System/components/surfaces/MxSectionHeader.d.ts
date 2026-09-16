import type { ReactNode } from 'react';

export interface MxSectionHeaderProps {
  title?: ReactNode;
  /** Optional sub-label under the title. */
  caption?: ReactNode;
  /** Trailing action label (e.g. "See all"). */
  action?: ReactNode;
  onAction?: () => void;
  node?: string;
}

/** Section / list header with title, optional caption, and a trailing text action. Base class `section-head`. */
export function MxSectionHeader(props: MxSectionHeaderProps): JSX.Element;
