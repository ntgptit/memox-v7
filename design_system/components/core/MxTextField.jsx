import React from 'react';

/**
 * The app's text input. Outlined, never filled: a fill makes the field a block
 * that competes with the cards around it. Focus shifts the border's HUE and never
 * its width — Material's 1px -> 2px jump nudges everything laid out beside it.
 *
 * It knows nothing about the rules it enforces: maxLength is a number the caller
 * supplies and errorText a string the caller has already localized.
 */
export function MxTextField({
  label,
  value,
  onChange,
  hintText,
  helperText,
  errorText,
  isEnabled = true,
  isReadOnly = false,
  maxLength,
  maxLines = 1,
  type = 'text',
  onSurface = false,
  autoFocus = false,
}) {
  const id = React.useId();
  const wrap = ['mx-field', errorText ? 'mx-field--error' : '', !isEnabled ? 'mx-field--disabled' : ''].filter(Boolean).join(' ');
  const shared = {
    id,
    className: 'mx-field__input',
    value,
    onChange: (e) => onChange && onChange(e.target.value),
    placeholder: hintText || ' ',
    disabled: !isEnabled,
    readOnly: isReadOnly,
    maxLength,
    autoFocus,
  };
  const help = errorText || helperText;
  return (
    <div className={wrap} style={{ '--color-surface-bg': onSurface ? 'var(--color-surface)' : 'var(--color-background)' }}>
      {maxLines > 1
        ? <textarea {...shared} rows={maxLines} />
        : <input {...shared} type={type} />}
      <label className="mx-field__label" htmlFor={id}>{label}</label>
      {(help || maxLength) ? (
        <div className="mx-field__help">
          <span>{help}</span>
          {maxLength ? <span>{(value || '').length}/{maxLength}</span> : null}
        </div>
      ) : null}
    </div>
  );
}
