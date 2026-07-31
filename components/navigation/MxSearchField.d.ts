import type { HTMLAttributes } from 'react';

export interface MxSearchFieldProps
  extends Omit<HTMLAttributes<HTMLInputElement>, 'onChange' | 'onSubmit'> {
  /** Controlled. Reported as typed; the component does not debounce. */
  value: string;
  onChanged?: (value: string) => void;
  /** Already-localized. Visible hint — "Search cards". */
  placeholder?: string;
  /**
   * Already-localized, and required in practice: the placeholder disappears the
   * moment the user types, which is exactly when a screen reader is most likely to
   * be asked what this field is.
   */
  semanticLabel: string;
  /** Already-localized. Names the clear button — "Clear search". */
  clearLabel: string;
  isEnabled?: boolean;
  shouldAutofocus?: boolean;
  /** Enter. Optional: a filter that updates as you type has nothing to submit. */
  onSubmitted?: (value: string) => void;
}

export declare function MxSearchField(props: MxSearchFieldProps): JSX.Element;
export default MxSearchField;
