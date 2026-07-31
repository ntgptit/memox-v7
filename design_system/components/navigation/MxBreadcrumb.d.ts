import * as React from 'react';

export interface MxBreadcrumbItem {
  /** Already-localized, or a user's own deck name. */
  label: string;
  /** Omit for the step the user is already on — it renders as quiet text. */
  onTap?: () => void;
}

export interface MxBreadcrumbProps {
  /** Ordered from the top of the hierarchy down. An empty list renders nothing at all. */
  items: MxBreadcrumbItem[];
  /** Names the strip — "deck path", not the path itself. */
  semanticLabel?: string;
  /** Material Icons name shown before the first step, e.g. "home" for the library root. */
  rootIcon?: string;
  /** Above this many steps the middle folds into an expandable "…". Default 4. */
  collapseAfter?: number;
}

export declare function MxBreadcrumb(props: MxBreadcrumbProps): React.JSX.Element;
