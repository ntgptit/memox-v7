import type { HTMLAttributes } from 'react';

export interface MxProgressBarProps extends HTMLAttributes<HTMLDivElement> {
  /**
   * 0 to 1, clamped. `null` is indeterminate — use it only when there genuinely
   * is no total, never to dress up a total the caller could have computed.
   */
  value?: number | null;
  /**
   * Already-localized, and required. A bare bar announces nothing at all, so the
   * user is told neither what is progressing nor when it stops.
   */
  semanticLabel: string;
  /** Already-localized. Optional visible caption above the track. */
  label?: string;
  /**
   * Already-localized and already formatted — "3 of 20". This component does no
   * number formatting and no pluralisation, because it would do both in one
   * language.
   */
  valueLabel?: string;
}

export declare function MxProgressBar(props: MxProgressBarProps): JSX.Element;
export default MxProgressBar;
