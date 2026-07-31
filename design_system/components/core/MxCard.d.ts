import * as React from 'react';

/**
 * A bordered, elevated panel — the flashcard, a deck row, a settings group.
 *
 */
/**
 * A bordered, elevated panel — the flashcard, a deck row, a settings group.
 *
 * @startingPoint section="Core" subtitle="The bordered panel every surface is built on" viewport="700x380"
 */
export interface MxCardProps {
  children?: React.ReactNode;
  /** none returns it to a flat bordered panel — what a card INSIDE another surface wants. */
  elevation?: 'none' | 'flat' | 'card' | 'raised' | 'overlay';
  /** Makes the whole card one target rather than requiring a nested button. */
  onClick?: () => void;
  /** Defaults to --space-lg. Settings groups use vertical --space-xs and pad their rows. */
  padding?: string;
  className?: string;
  style?: React.CSSProperties;
}

export declare function MxCard(props: MxCardProps): React.JSX.Element;
