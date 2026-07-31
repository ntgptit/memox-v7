import * as React from 'react';

export interface MxLoadingStateProps {
  /** Already-localized, and required: a bare spinner announces nothing at all. */
  semanticsLabel: string;
}

export declare function MxLoadingState(props: MxLoadingStateProps): React.JSX.Element;
