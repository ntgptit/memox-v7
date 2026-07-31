import type { HTMLAttributes, ReactNode } from 'react';

/**
 * How far the card sits above the page.
 *
 * `none` returns it to a flat bordered panel, which is what a card *inside*
 * another surface wants — a shadow stacked on a shadow reads as a rendering fault
 * rather than as depth.
 */
export type MxCardElevation = 'none' | 'card' | 'raised' | 'overlay';

export interface MxCardProps extends Omit<HTMLAttributes<HTMLElement>, 'onClick'> {
  children?: ReactNode;
  elevation?: MxCardElevation;
  /** Makes the whole card one target. Omit to leave it a plain surface. */
  onTap?: (() => void) | null;
}

export declare function MxCard(props: MxCardProps): JSX.Element;
export default MxCard;
