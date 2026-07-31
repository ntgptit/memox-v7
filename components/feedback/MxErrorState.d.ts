import type { HTMLAttributes } from 'react';

export interface MxErrorStateProps extends HTMLAttributes<HTMLDivElement> {
  /** Already-localized, and already free of technical detail. */
  title: string;
  /** Already-localized. Never a raw error message — see the prompt. */
  message: string;
  /** Supply with `onRetry` or not at all. */
  retryLabel?: string;
  onRetry?: () => void;
}

export declare function MxErrorState(props: MxErrorStateProps): JSX.Element;
export default MxErrorState;
