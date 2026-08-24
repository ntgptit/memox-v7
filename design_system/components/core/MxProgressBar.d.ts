import * as React from 'react';

/**
 * Determinate progress — how much of a deck is learned, how far a session has run.
 *
 * @startingPoint section="Core" subtitle="Deck and session progress" viewport="700x380"
 */
export interface MxProgressBarProps {
  /** 0 to 1. Clamped, because a caller dividing by a zero-card deck should not draw a bar off the edge. */
  value: number;
  /** Already-localized. Shown above the bar and used as the accessible name. */
  label?: string;
  /** The right-hand figure — "62%", "12 of 20". Already formatted. */
  valueLabel?: string;
  /** sm is the 4px bar inside a deck card; md is the 8px session bar. */
  size?: 'sm' | 'md';
  /** `flush` squares the track's ends for a bar used as an EDGE — the deck card
   * seats one on its base, where a pill end adds a second rounding inside the
   * card's own 16px corner and the track reads as a lozenge tucked into it. The
   * container then owns the clipping. */
  shape?: 'pill' | 'flush';
  /** streak draws in the streak colour — for a run of days rather than a proportion learned. */
  tone?: 'progress' | 'streak';
  /** Whether `label` and `valueLabel` are DRAWN. They are always announced.
   * `false` gives a bare track — the deck hero's collapsed state — without
   * costing the bar its accessible name. */
  isLabelPainted?: boolean;
}

export declare function MxProgressBar(props: MxProgressBarProps): React.JSX.Element;
