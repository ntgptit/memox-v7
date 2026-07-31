import React from 'react';

import MxIcon from '../core/MxIcon.jsx';

/**
 * Filtering a list by what the user types.
 *
 * Not `MxTextField` with an icon bolted on. Search differs from a form field in
 * three ways that are all visible: it has no persistent label (the leading glyph and
 * the placeholder together are the name, and there is no value to re-read later), it
 * has a clear affordance, and it reports as it is typed rather than on submit. Those
 * differences are the component; sharing the input would mean a `variant` on
 * `MxTextField` that turns off the one prop it makes required.
 *
 * It does not debounce and it does not search. Both belong to the caller: how long
 * to wait depends on what the query costs, and a shared control guessing at that is
 * a control that is wrong on the one screen where the read is expensive.
 */
export function MxSearchField({
  value,
  onChanged,
  placeholder,
  semanticLabel,
  clearLabel,
  isEnabled = true,
  shouldAutofocus = false,
  onSubmitted,
  id,
  className = '',
  ...rest
}) {
  const generatedId = React.useId();
  const fieldId = id ?? `mx-search-${generatedId}`;
  const hasValue = value != null && value !== '';

  return (
    <div
      className={[
        'mx-search',
        !isEnabled ? 'mx-search--disabled' : '',
        className,
      ]
        .filter(Boolean)
        .join(' ')}
    >
      <MxIcon name="search" size="md" />
      <input
        id={fieldId}
        // `type="search"` for the keyboard it brings up and the semantics it
        // carries; the browser's own clear button is suppressed in CSS, because it
        // appears on one engine at a size no guideline covers and would stand beside
        // the one this component draws.
        type="search"
        className="mx-search__input"
        value={value}
        placeholder={placeholder}
        // The placeholder is not the name. It disappears the moment the user types,
        // which is exactly when a screen reader is most likely to be asked what this
        // field is.
        aria-label={semanticLabel}
        disabled={!isEnabled}
        autoFocus={shouldAutofocus}
        enterKeyHint="search"
        autoComplete="off"
        autoCorrect="off"
        spellCheck={false}
        onChange={(event) => onChanged?.(event.target.value)}
        onKeyDown={(event) => {
          if (event.key === 'Enter' && onSubmitted) onSubmitted(value ?? '');
          // Escape clears rather than blurring. A user who has typed a query into a
          // filter wants the list back, not the focus gone.
          if (event.key === 'Escape' && hasValue) {
            event.preventDefault();
            onChanged?.('');
          }
          rest.onKeyDown?.(event);
        }}
        {...rest}
      />
      {/* Rendered only when there is something to clear. A permanently visible
          clear button on an empty field is a control that does nothing, and the
          user has to find that out by pressing it. */}
      {hasValue && isEnabled ? (
        <button
          type="button"
          className="mx-search__clear mx-focus-ring"
          aria-label={clearLabel}
          onClick={() => onChanged?.('')}
        >
          <MxIcon name="close" size="sm" />
        </button>
      ) : null}
    </div>
  );
}

export default MxSearchField;
