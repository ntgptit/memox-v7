import type { HTMLAttributes } from 'react';

export interface MxLoadingStateProps extends HTMLAttributes<HTMLDivElement> {
  /**
   * Already-localized, and required. A bare spinner announces nothing at all, so
   * the user is told neither that something is happening nor when it stops.
   */
  semanticsLabel: string;
}

export declare function MxLoadingState(props: MxLoadingStateProps): JSX.Element;
export default MxLoadingState;
