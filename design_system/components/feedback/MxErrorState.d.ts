import * as React from 'react';

export interface MxErrorStateProps {
  /** Already-localized, and already free of technical detail. */
  title: string;
  /** Never a raw Failure message — that is written for whoever reads a log. */
  message: string;
  /** Retry needs both a label and a callback, or neither. */
  retryLabel?: string;
  onRetry?: () => void;
}

export declare function MxErrorState(props: MxErrorStateProps): React.JSX.Element;
