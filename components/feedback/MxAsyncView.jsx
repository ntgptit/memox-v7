import React from 'react';

import MxLoadingState from './MxLoadingState.jsx';

/**
 * Renders the three cases of an async value with one loading treatment.
 *
 * What it centralises is a POLICY, not four lines of branching. Every call site
 * silently inherits an answer to "does a refresh show a spinner", and the default
 * is not obvious. This is the answer, written down once:
 *
 *  - **Refresh keeps the previous value.** A resume that re-reads the deck list
 *    must not flash a spinner over a populated screen. Motion in place of
 *    information.
 *  - **Reload does not.** A dependency changing means the previous value answers a
 *    question nobody is asking any more.
 *  - **Initial load always shows the spinner**, because with no previous value
 *    there is nothing to keep showing. A screen therefore never shows stale data
 *    as if it were fresh.
 *
 * Loading is shared; error copy is not. A spinner with a screen-reader label is the
 * same everywhere, so this component owns it. The words on a failure are the
 * screen's to choose, so `error` is a render function the caller supplies — and
 * there is deliberately no default: a generic "something went wrong" is how every
 * screen ends up with the same unhelpful sentence.
 */
export function MxAsyncView({ value, loadingLabel, data, error, loadingFrame }) {
  const renderLoading = () => {
    const loading = <MxLoadingState semanticsLabel={loadingLabel} />;

    return loadingFrame ? loadingFrame(loading) : loading;
  };

  if (value.isLoading) {
    // `hasValue` and not `data !== undefined`: a resolved value can legitimately
    // be `undefined`, and treating that as "nothing yet" would flash a spinner
    // over a screen that had already answered.
    if (value.isRefreshing && value.hasValue) return data(value.data);

    return renderLoading();
  }

  if (value.hasError) return error(value.error, value.stackTrace);

  return data(value.data);
}

export default MxAsyncView;
