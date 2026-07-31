import * as React from 'react';

export interface MxSearchFieldProps {
  value: string;
  onChange: (value: string) => void;
  /** Already-localized, and it should name the SCOPE: "Search in Academic Word List". */
  placeholder: string;
  /** Shown as a count chip while there is a query. Omit if the screen does not know yet. */
  resultCount?: number;
  autoFocus?: boolean;
}

export declare function MxSearchField(props: MxSearchFieldProps): React.JSX.Element;
