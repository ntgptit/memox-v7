import type { HTMLAttributes, ReactNode } from 'react';

export interface MxContentShellProps extends Omit<HTMLAttributes<HTMLDivElement>, 'title'> {
  children?: ReactNode;
  /** Already-localized. Omit to render a screen with no app bar. */
  title?: string;
  /** App-bar actions, usually `MxIconButton`s. */
  actions?: ReactNode;
  /** A back or menu control, before the title. */
  leading?: ReactNode;
  /**
   * Screen padding. Omit — the default — to take the gutter for the current
   * width: 16, or 12 below the compact breakpoint.
   */
  padding?: string;
  /**
   * Whether the body should scroll once it no longer fits. Opt-in, and it has to
   * be: a body that already scrolls must not be nested inside another scroll
   * container, and a fixed body such as a form must scroll or it overflows the
   * moment the screen gets shorter.
   */
  isScrollable?: boolean;
  /** The screen's primary create action. Reserves no space. */
  floatingActionButton?: ReactNode;
  /** An `MxNavigationBar`, when this screen sits inside one. */
  navigationBar?: ReactNode;
}

export declare function MxContentShell(props: MxContentShellProps): JSX.Element;
export default MxContentShell;
