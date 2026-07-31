import * as React from 'react';

export interface MxAsyncViewProps<T = unknown> {
  status: 'loading' | 'error' | 'data';
  value?: T;
  error?: unknown;
  /** Already-localized spinner label. */
  loadingLabel: string;
  data: (value: T) => React.ReactNode;
  /** No default on purpose: a generic "something went wrong" is how every screen ends up with the same unhelpful sentence. */
  renderError: (error: unknown) => React.ReactNode;
  /** Chrome to put around the spinner when the screen's title is not knowable yet. */
  loadingFrame?: (loading: React.ReactNode) => React.ReactNode;
}

export declare function MxAsyncView<T>(props: MxAsyncViewProps<T>): React.JSX.Element;
