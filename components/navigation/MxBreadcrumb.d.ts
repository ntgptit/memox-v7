import type { HTMLAttributes } from 'react';

/**
 * One step in an `MxBreadcrumb`.
 *
 * A plain value with no domain type in it: the component is told a name and what
 * to do, and knows nothing about decks, folders or anything else it might be
 * pointing at. That is what keeps it shared.
 */
export interface MxBreadcrumbItem {
  /** Already-localized, or the user's own text. */
  label: string;
  /** `null` marks the step the user is already on. */
  onTap?: (() => void) | null;
  /** Stable identity when two steps can share a label. */
  key?: string;
}

export interface MxBreadcrumbProps extends HTMLAttributes<HTMLElement> {
  /** Ordered from the top of the hierarchy to the current step. Empty renders nothing. */
  items: MxBreadcrumbItem[];
  /** Names the strip for assistive technology — "deck path", not the path itself. */
  semanticLabel?: string;
}

export declare function MxBreadcrumb(props: MxBreadcrumbProps): JSX.Element | null;
export default MxBreadcrumb;
