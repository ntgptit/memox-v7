import type { HTMLAttributes } from 'react';

export interface MxTextFieldProps
  extends Omit<HTMLAttributes<HTMLElement>, 'onChange' | 'onSubmit'> {
  /** Controlled. The component never trims or reformats what it is given. */
  value: string;
  onChanged?: (value: string) => void;
  /**
   * Already-localized, and required. Not optional, because a floating label is the
   * only persistent name the field has: a hint-only field is unlabelled the moment
   * the user types, both on screen and to a screen reader.
   */
  label: string;
  /** Already-localized. Appears with the floating label, not before it. */
  hintText?: string;
  helperText?: string;
  /**
   * Already-localized. Non-null puts the field in its error state. The state is
   * carried by real error text rather than a boolean, so the error is never
   * expressed by colour alone.
   */
  errorText?: string;
  isEnabled?: boolean;
  /**
   * Focusable and selectable, but not editable. Distinct from `isEnabled: false`,
   * which greys the field and removes it from the focus order.
   */
  isReadOnly?: boolean;
  inputType?: 'text' | 'email' | 'password' | 'search' | 'tel' | 'url';
  inputMode?: 'text' | 'numeric' | 'decimal' | 'email' | 'search' | 'tel' | 'url' | 'none';
  enterKeyHint?: 'enter' | 'done' | 'go' | 'next' | 'previous' | 'search' | 'send';
  minLines?: number;
  /** `null` lets the field grow without limit — what a front/back editor wants. */
  maxLines?: number | null;
  /** The caller's limit. Drives the counter and the input's own cap. */
  maxLength?: number;
  shouldAutofocus?: boolean;
  /** Single-line only: Enter has a newline to insert in a multiline field. */
  onSubmitted?: (value: string) => void;
}

export declare function MxTextField(props: MxTextFieldProps): JSX.Element;
export default MxTextField;
