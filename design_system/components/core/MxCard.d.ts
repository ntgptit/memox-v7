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
  /** Makes the whole card one target. The card stays a plain surface — the target
   * is a full-bleed overlay under the content — so it may still hold controls. */
  onClick?: () => void;
  /** Names that overlay for a screen reader. The overlay carries no text of its
   * own, and the content above it is a sibling rather than the button's label,
   * so without this the card announces as an unnamed button. Required in
   * practice whenever `onClick` is passed. */
  actionLabel?: string;
  /** Defaults to --space-lg. Settings groups use vertical --space-xs and pad their rows. */
  padding?: string;
  className?: string;
  style?: React.CSSProperties;
}

export declare function MxCard(props: MxCardProps): React.JSX.Element;
