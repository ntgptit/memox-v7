import React from 'react';
import { MxLoadingState } from './MxLoadingState.jsx';

/**
 * The three cases of an async read with one loading treatment. Loading is
 * shared; error COPY is not — "couldn't load your decks" is not "couldn't load
 * this deck", so `error` is a builder the caller supplies and there is
 * deliberately no default.
 */
export function MxAsyncView({ status, value, error, loadingLabel, data, renderError, loadingFrame }) {
  if (status === 'loading') {
    const loading = <MxLoadingState semanticsLabel={loadingLabel} />;
    return loadingFrame ? loadingFrame(loading) : loading;
  }
  if (status === 'error') return renderError(error);
  return data(value);
}
