import React from 'react';
import { MxIconButton } from './MxIconButton.jsx';

/**
 * The app's text input. Outlined, never filled: a fill makes the field a block
 * that competes with the cards around it. Focus shifts the border's HUE and never
 * its width — Material's 1px -> 2px jump nudges everything laid out beside it.
 *
 * It knows nothing about the rules it enforces: maxLength is a number the caller
 * supplies and errorText a string the caller has already localized.
 *
 * `trailingAction` is a typed triple — `{ icon, semanticLabel, onClick }` — and
 * not a slot. A slot would let a caller put a second text style, a coloured
 * glyph or a whole row inside a field, which is the exact thing this component
 * refuses. It exists because a field whose only way to commit is the keyboard's
 * Enter has an action nobody can see. `onClick` omitted leaves it visible and
 * inert, so the button does not appear under the finger as the first character
 * lands.
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
  trailingAction,
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
      {trailingAction ? (
        <span className="mx-field__action">
          <MxIconButton
            icon={trailingAction.icon}
            semanticLabel={trailingAction.semanticLabel}
            onClick={trailingAction.onClick}
          />
        </span>
      ) : null}
      {(help || maxLength) ? (
        <div className="mx-field__help">
          <span>{help}</span>
          {maxLength ? <span>{(value || '').length}/{maxLength}</span> : null}
        </div>
      ) : null}
    </div>
  );
}
