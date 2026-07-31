import React from 'react';

/**
 * The app's text input.
 *
 * Takes no colour, no text style and no decoration: every visual decision lives in
 * the stylesheet, which is where focus, error and disabled are already defined
 * once for the whole app. A caller able to pass decoration would be able to invent
 * a second input style, and the first screen to do it would look correct in
 * isolation and wrong beside the others.
 *
 * It knows nothing about the rules it enforces. `maxLength` is a number the caller
 * supplies and `errorText` is a string the caller has already localized and
 * already decided to show. A shared input carrying a business limit is a business
 * rule nobody can find, and it is wrong the moment a second screen has a different
 * limit.
 *
 * It also does not trim. Trimming here would silently change what the caller
 * validated, so the value it reports and the value it was given stay the same
 * string.
 */
export function MxTextField({
  value,
  onChanged,
  label,
  hintText,
  helperText,
  errorText,
  isEnabled = true,
  isReadOnly = false,
  inputType = 'text',
  inputMode,
  enterKeyHint,
  minLines,
  maxLines = 1,
  maxLength,
  shouldAutofocus = false,
  onSubmitted,
  id,
  className = '',
  ...rest
}) {
  const generatedId = React.useId();
  const fieldId = id ?? `mx-field-${generatedId}`;
  const helperId = `${fieldId}-helper`;

  const hasError = errorText != null;
  // The floating label is driven by the value, not by a `focused` state this
  // component would have to track: focus is already `:focus-within` in CSS, and
  // two sources for one piece of state is how they disagree.
  const isFloating = value != null && value !== '';
  const isMultiline = maxLines == null || maxLines > 1;

  const commonProps = {
    id: fieldId,
    className: 'mx-field__input',
    value,
    // A hint appears WITH the floating label, never before it: two pieces of grey
    // text in the same box is one too many. The stylesheet hides it until focus,
    // so the attribute is safe to set unconditionally.
    placeholder: hintText ?? ' ',
    disabled: !isEnabled,
    readOnly: isReadOnly,
    autoFocus: shouldAutofocus,
    inputMode,
    enterKeyHint,
    maxLength,
    // The message is what carries the error, not the outline. A red border with no
    // text tells a colour-blind user that something is different and not what.
    'aria-invalid': hasError || undefined,
    'aria-describedby': errorText || helperText ? helperId : undefined,
    onChange: (event) => onChanged?.(event.target.value),
    ...rest,
  };

  return (
    <div
      className={[
        'mx-field',
        isFloating ? 'mx-field--floating' : '',
        hasError ? 'mx-field--error' : '',
        !isEnabled ? 'mx-field--disabled' : '',
        className,
      ]
        .filter(Boolean)
        .join(' ')}
    >
      <div className="mx-field__shell">
        {isMultiline ? (
          <textarea
            {...commonProps}
            rows={minLines ?? 3}
            // Enter inserts a newline in a multiline field, so there is no submit
            // to report. A caller wanting one on a text area is asking for a key
            // the user needs for the content.
            style={maxLines == null ? undefined : { maxHeight: `${maxLines * 1.5}em` }}
          />
        ) : (
          <input
            {...commonProps}
            type={inputType}
            onKeyDown={(event) => {
              if (event.key === 'Enter' && onSubmitted) onSubmitted(value ?? '');
              rest.onKeyDown?.(event);
            }}
          />
        )}
        <label className="mx-field__label mx-type-body-large" htmlFor={fieldId}>
          {label}
        </label>
        {/* The outline is a real fieldset so the floating label can cut a notch in
            it rather than being drawn over a line it then has to hide. Hidden from
            the accessibility tree: the `<label>` above already names the field, and
            a second copy would have the reader say it twice. */}
        <fieldset className="mx-field__outline" aria-hidden="true">
          <legend className="mx-field__legend">
            <span>{label}</span>
          </legend>
        </fieldset>
      </div>

      {errorText || helperText || maxLength != null ? (
        <div className="mx-field__footer mx-type-body-small">
          <span
            id={helperId}
            className={hasError ? 'mx-field__message--error' : undefined}
            // Only the error is live. A helper that announced itself on every
            // keystroke would talk over the user typing.
            role={hasError ? 'alert' : undefined}
          >
            {errorText ?? helperText}
          </span>
          {maxLength != null ? (
            <span className="mx-field__counter">{`${(value ?? '').length}/${maxLength}`}</span>
          ) : null}
        </div>
      ) : null}
    </div>
  );
}

export default MxTextField;
