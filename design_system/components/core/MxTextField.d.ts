import * as React from 'react';

export interface MxTextFieldProps {
  /** Already-localized, and required — a hint-only field is unlabelled the moment the user types. */
  label: string;
  value: string;
  onChange?: (value: string) => void;
  hintText?: string;
  helperText?: string;
  /** Already-localized. Non-null puts the field in its error state; the state is never colour alone. */
  errorText?: string;
  isEnabled?: boolean;
  /** Focusable and selectable but not editable — distinct from disabled. */
  isReadOnly?: boolean;
  /** The caller's limit. Business rules live with the feature that owns them. */
  maxLength?: number;
  /** >1 renders a textarea — what a front/back card editor wants. */
  maxLines?: number;
  type?: string;
  /** True when the field sits on a card rather than the page, so the floating label's backing matches. */
  onSurface?: boolean;
  autoFocus?: boolean;
}

export declare function MxTextField(props: MxTextFieldProps): React.JSX.Element;
