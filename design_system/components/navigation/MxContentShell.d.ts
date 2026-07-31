import * as React from 'react';

/**
 * The frame every memox screen is built in: app bar, gutters, optional FAB.
 *
 */
/**
 * The frame every memox screen is built in: app bar, gutters, optional FAB.
 *
 * @startingPoint section="Screens" subtitle="App bar, page gutters and floating action" viewport="700x300"
 */
export interface MxContentShellProps {
  /** Already-localized. Omit entirely for a screen with no app bar. */
  title?: string;
  /** Usually an MxIconButton — back or close. */
  leading?: React.ReactNode;
  actions?: React.ReactNode;
  /** Pinned between the app bar and the scrolling body — a breadcrumb, a search field. Stays put while the body scrolls. */
  subheader?: React.ReactNode;
  children?: React.ReactNode;
  /** Defaults to --space-lg, or --space-md below the 360px breakpoint. Pass "0" when the body owns its gutters. */
  padding?: string;
  /** Opt-in: a body that already scrolls must not be nested inside another scroll view. */
  isScrollable?: boolean;
  /** The screen's one create action. It reserves no space — the body pads its own bottom. */
  fab?: { icon?: string; label: string; onPress: () => void };  isCompact?: boolean;
  style?: React.CSSProperties;
}

export declare function MxContentShell(props: MxContentShellProps): React.JSX.Element;
