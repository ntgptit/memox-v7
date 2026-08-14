import * as React from 'react';

export interface MxErrorStateProps {
  /** Already-localized, and already free of technical detail. */
  title: string;
  /** Never a raw Failure message — that is written for whoever reads a log. */
  message: string;
  /** Retry needs both a label and a callback, or neither. */
  retryLabel?: string;
  onRetry?: () => void;
  /**
   * Whether the retry the user asked for is still running.
   *
   * Without it the control is a lie: re-reading the same source is a refresh,
   * and a refresh repaints the same error face, so a press produces nothing on
   * screen. `MxActionButton` already renders this — the label keeps its slot at
   * zero opacity with the spinner over it, so the button does not resize.
   */
  isRetrying?: boolean;
}

export declare function MxErrorState(props: MxErrorStateProps): React.JSX.Element;
