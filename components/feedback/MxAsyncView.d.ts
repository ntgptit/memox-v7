import type { ReactNode } from 'react';

/**
 * The three cases of an asynchronous read, plus the two flags that separate a
 * refresh from a reload.
 *
 * Mirrors Riverpod's `AsyncValue`: `isLoading` can be true *while* a previous
 * value is still held, which is exactly the case the refresh policy exists for.
 */
export interface MxAsyncValue<T> {
  isLoading: boolean;
  hasValue: boolean;
  hasError?: boolean;
  data?: T;
  error?: unknown;
  stackTrace?: string;
  /** A re-read of the same question. The previous value stays on screen. */
  isRefreshing?: boolean;
}

export interface MxAsyncViewProps<T> {
  value: MxAsyncValue<T>;
  /**
   * Already-localized, and required. A bare spinner announces nothing at all.
   */
  loadingLabel: string;
  data: (value: T) => ReactNode;
  /**
   * The failure itself must not reach the user. Map the error *type* to copy
   * inside this function; a raw message is written for whoever reads a log.
   */
  error: (error: unknown, stackTrace?: string) => ReactNode;
  /**
   * Chrome to put around the loading widget, when a screen needs some. Exists
   * because a screen whose title comes from the loaded data cannot put one shell
   * around all three branches — the title is not known yet while it loads.
   */
  loadingFrame?: (loading: ReactNode) => ReactNode;
}

export declare function MxAsyncView<T>(props: MxAsyncViewProps<T>): JSX.Element;
export default MxAsyncView;
